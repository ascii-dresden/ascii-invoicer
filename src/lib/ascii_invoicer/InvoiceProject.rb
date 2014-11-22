# encoding: utf-8
require 'yaml'
require 'date'
require 'euro'
libpath = File.dirname __FILE__

require File.join libpath, 'hash_transformer.rb'

require File.join libpath, 'projectFileReader.rb'
require File.join libpath, 'rfc5322_regex.rb'
require File.join libpath, 'texwriter.rb'

## TODO requirements and validity
## TODO open, YAML::parse, [transform, ] read_all, generate, validate
## TODO statemachine!!
# http://www.zenspider.com/Languages/Ruby/QuickRef.html
class InvoiceProject < LuigiProject
  attr_reader :project_path, :project_folder,
    :raw_data,
    :status,    :errors,
    :settings,  :defaults

  attr_writer :raw_data, :defaults

  include TexWriter
  include Filters
  include ProjectFileReader

  @@known_keys= [ # list default values here
    :format,    :lang,      :created,
    :client,    :event,     :manager,
    :offer,     :invoice,   :canceled,
    :messages,  :products,  :hours,
    :includes
  ]

  @@dynamic_keys=[
    :client_addressing,
    :hours_time,
    :hours_total,
    :event_date,
    :event_prettydate,
    :caterers,
    :offer_number,
    :offer_costs,    :offer_taxes,   :offer_total,   :offer_final,
    :invoice_costs,  :invoice_taxes, :invoice_total, :invoice_final,
    :invoice_longnumber,
    :productsbytax
  ]

  #def initialize(project_path = nil, template_path = nil, settings = $settings, name = nil)
  def initialize(hash)
    @path          = hash[:path]
    @settings      = hash[:settings]
    @template_path = hash[:template_path]
    @data          = hash[:data]
    @data        ||= {}

    @name          = File.basename @path, '.yml'
    @settings      = hash[:settings]
    @status        = :ok # :ok, :canceled, :unparsable
    @errors        = []
    @defaults      = {}
    @defaults      = @settings[:defaults] unless @settings[:defaults].nil?

    @defaults['format']     = '1.0.0'
    @logger                 = Logger.new STDOUT
    @texlogger              = Logger.new STDOUT
    @filter_logger          = Logger.new STDOUT
    @reader_logger          = Logger.new STDOUT
    @logger.progname        = "ascii-invoicer project_parser"
    @texlogger.progname     = "ascii-invoicer tex_writer"
    @filter_logger.progname = "ascii-invoicer filter"
    @reader_logger.progname = "ascii-invoicer reader"

    unless @template_path.nil?
      create @template_path
    end

    open(@path) unless @path.nil?
  end

  ## open given .yml and parse into @raw_data
  def open(project_path)
    #puts "opening \"#{project_path}\""
    raise "already opened another project" unless @project_path.nil?
    @project_path   = project_path
    @project_folder = File.split(project_path)[0]

    error "FILE \"#{project_path}\" does not exist!" unless File.exists?(project_path)

    ## setting the name
    @data[:name] = File.basename File.split(@project_path)[0]

    ## opening the project file
    begin
      @raw_data        = YAML::load(File.open(project_path))
    rescue SyntaxError => error
      @logger.warn "error parsing #{project_path}"
      puts error
      @status = :unparsable
      return false
    else
      @data[:valid] = true # at least for the moment
      @status = :ok
      @data[:project_path]  = project_path
    end

    #load format and transform or not
    @data[:format] = @raw_data['format'] ? @raw_data['format'] : "1.0.0"
    if @data[:format] < "2.4.0"
      begin
        @raw_data = import_100 @raw_data
      rescue =>error
        @status = :unparsable
        @logger.warn "#{error} parsing #{@project_path}"
        puts $@
        return false
      end
    end

    prepare_data()
    return true
  end

  # displays "CANCELED: name if canceled"
  def pretty_name
    @data[:canceled] ? "CANCELED: #{@data[:name]}" : @data[:name]
  end

  # returns the name (LuigiProject Interface)
  def name
    @data[:name]
  end

  # returns the date (LuigiProject Interface)
  def date
    return @data[:event][:date] if @data[:event][:date]
    return @data[:created]      if @data[:created]
    return Date.parse "01.01.0000"
  end

  # returns the manager
  def manager
    data :manager
  end

  def path
    @project_path
  end

  def fill_template
    project_name = @name.sub(?_, " ") #latex build fails if values contain a "_"
    manager_name = @settings.manager_name
    version = @settings.version
    template = File.basename(@template_path, ".yml.erb")

    return binding()
  end

  # returns index for sorting (year+invoicenumber)
  def index
    return date.year.to_s + @data[:invoice][:number] if @data[:invoice][:number]
    return date.year.to_s + "Zzz"
  end

  ## currently only from 1.0.0 to 2.4.0 Format
  def import_100 hash
    rules = [
      { old:"client",       new:"client/fullname"   },
      { old:"address",      new:"client/address"    },
      { old:"email",        new:"client/email"      },
      { old:"event",        new:"event/name"        },
      { old:"location",     new:"event/location"    },
      { old:"description",  new:"event/description" }, #trim
      { old:"manumber",     new:"offer/number"      },
      { old:"anumber",      new:"offer/appendix"    },
      { old:"rnumber",      new:"invoice/number"    },
      { old:"payed_date",   new:"invoice/payed_date"},
      { old:"invoice_date", new:"invoice/date"      },
      { old:"signature",    new:"manager"           }, #trim
      #{ old:"hours/time",  new:"hours/total"       },
    ]
    ht = HashTransformer.new :rules => rules, :original_hash => hash
    new_hash = ht.transform()
    new_hash[ 'created' ] = "01.01.0000"

    date = strpdates(hash['date'])
    new_hash.set_path("event/dates/0/begin", date[0])
    new_hash.set_path("event/dates/0/end",   date[1]) unless date[1].nil?
    new_hash.set_path("event/dates/0/time/begin", new_hash.get_path("time"))     if date[1].nil?
    new_hash.set_path("event/dates/0/time/end",   new_hash.get_path("time_end")) if date[1].nil?

    new_hash['manager']= new_hash['manager'].lines.to_a[1] if new_hash['manager'].lines.to_a.length > 1

    if new_hash.get_path("client/fullname").words.class == Array
      new_hash.set_path("client/title",     new_hash.get_path("client/fullname").lines.to_a[0].strip)
      new_hash.set_path("client/last_name", new_hash.get_path("client/fullname").lines.to_a[1].strip)
      new_hash.set_path("client/fullname",  new_hash.get_path("client/fullname").gsub("\n",' ').strip)
    else
      fail_at :client_fullname
    end
    new_hash.set_path("offer/date", Date.today)
    new_hash.set_path("invoice/date", Date.today) unless new_hash.get_path("invoice/date")

    return hash
  end

  def products
    data :products
  end


  def prepare_data
    @@known_keys.each {|key| read key }
    @@dynamic_keys.each {|key|
      value = apply_generator key, @data
      @data.set_path key, value, ?_, true # symbols = true
    }
  end

  def validate choice = :invoice
    blockers(choice).length == 0
  end

  def blockers choice = :invoice
    (invalidators = { # self explaiatory ain't it? :D
      #:invoice   => [:invoice_number, :products, :manager, :caterers],
      :invoice   => [:invoice_number, :products, :manager,],
      :archive   => [:invoice_number, :products, :manager, :invoice_payed_date, :archive, :payed_date],
      :payed     => [:invoice_number, :products, :manager, :invoice_payed_date, :payed_date],
      :offer     => [:offer_number]
    }[choice] & @errors)
  end

  def to_s
    name
  end

  def to_yaml
    @raw_data.to_yaml
  end


  #getters for path_through_document
  #getting path['through']['document']
  def data key = nil
    return @data if key.nil?
    return @data.get_path key
  end

  def export_filename choice, ext=""
    offer_number   = data 'offer/number'
    invoice_number = data 'invoice/number'
    name = data 'name'
    date = data('event/date').strftime "%Y-%m-%d"

    ext.prepend '.' unless ext.length > 0 and ext.start_with? '.'

    if choice == :invoice
      "#{invoice_number} #{name} #{date}#{ext}"
    elsif choice == :offer
      "#{offer_number} #{name}#{ext}"
    else
      return false
    end
  end
end

class InvoiceProduct
  attr_reader :name, :hash, :tax, :valid, :returned,
    :total_invoice, :cost_offer, :cost_invoice, :cost_offer,
    :tax_invoice, :tax_offer, :tax_value,
    :price, :unit

  def initialize(hash, settings)
    @hash      = hash
    @name      = hash[:name]
    @price     = hash[:price]
    @unit      = hash[:unit]
    @amount    = hash[:amount]
    @settings  = settings 
    if hash[:tax]
      @tax_value = hash[:tax]
    else
      @tax_value = @settings[:defaults][:tax]
    end

    fail "TAX MUST NOT BE > 1" if @tax_value > 1

    @valid = true
    calculate() unless hash.nil?
  end

  def to_s
    "#{@amount}/#{@sold} #{@name}, #{@price} cost (#{@cost_offer}|#{@cost_invoice}) total(#{@total_offer}|#{@total_invoice} #{@tax_value}) "
  end

  def calculate()
    return false if @hash.nil?
    @valid    = false unless @hash[:sold].nil? or @hash[:returned].nil?
    @valid    = false unless @hash[:amount] and @hash[:price]
    @sold     = @hash[:sold]
    @price    = @hash[:price].to_euro
    @amount   = @hash[:amount]
    @returned = @hash[:returned]

    if @sold
      @returned = @amount - @sold
    elsif @returned
      @sold = @amount - @returned
    else
      @sold = @amount
      @returned = 0
    end

    @hash[:cost_offer]   = @cost_offer   = (@price * @amount).to_euro
    @hash[:cost_invoice] = @cost_invoice = (@price * @sold).to_euro

    @hash[:tax_offer]    = @tax_offer    = (@cost_offer   * @tax_value)
    @hash[:tax_invoice]  = @tax_invoice  = (@cost_invoice * @tax_value)

    @hash[:total_offer]    = @total_offer    = (@cost_offer   + @tax_offer)
    @hash[:total_invoice]  = @total_invoice  = (@cost_invoice + @tax_invoice)
    self.freeze
  end

  def amount choice
    return @sold   if choice == :invoice
    return @amount if choice == :offer
    return -1
  end

  def cost choice
    return @cost_invoice if choice == :invoice
    return @cost_offer   if choice == :offer
    return -1.to_euro
  end

  def tax choice
    return @tax_invoice if choice == :invoice
    return @tax_offer   if choice == :offer
    return -1.to_euro
  end
end
