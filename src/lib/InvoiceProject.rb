# encoding: utf-8
require 'yaml'
require 'date'

require File.join File.dirname(__FILE__) + '/HashTransform.rb'
require File.join File.dirname(__FILE__) + '/Euro.rb'

require File.join File.dirname(__FILE__) + '/projectFileReader.rb'
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/texwriter.rb'

## TODO requirements and validity
## TODO open, YAML::parse, [transform, ] read_all, generate, validate
## TODO statemachine!!
# http://www.zenspider.com/Languages/Ruby/QuickRef.html
class InvoiceProject
  attr_reader :PROJECT_PATH, :PROJECT_FOLDER,
    :raw_data,
    :STATUS,    :ERRORS,
    :SETTINGS,  :DEFAULTS

  attr_writer :raw_data, :DEFAULTS

  include TexWriter
  include Filters
  include ProjectFileReader

  @@known_keys= [
    :format,    :lang,      :created,
    :client,    :event,     :manager,
    :offer,     :invoice,
    :messages,  :products,  :hours,
  ]

  @@dynamic_keys=[
    :client_addressing,
    :hours_total,
    :event_date,
    :event_prettydate,
    :offer_number,
    :offer_cost, :offer_tax, :offer_total,
    :invoice_cost, :invoice_tax, :invoice_total,
  ]

  def initialize(project_path = nil, settings = $SETTINGS, name = nil)
    @SETTINGS = settings
    @STATUS   = :ok # :ok, :canceled, :unparsable
    @ERRORS   = []
    @data     = {}
    @DEFAULTS = {}
    @DEFAULTS = @SETTINGS['defaults'] if @SETTINGS['defaults']

    @DEFAULTS['format'] = '1.0.0'

    open(project_path, name) unless project_path.nil?
  end

  ## open given .yml and parse into @raw_data
  def open(project_path, name = nil)
    #puts "opening \"#{project_path}\""
    raise "already opened another project" unless @PROJECT_PATH.nil?
    @PROJECT_PATH = project_path
    @PROJECT_FOLDER = File.split(project_path)[0]

    error "FILE \"#{project_path}\" does not exist!" unless File.exists?(project_path)

    ## setting the name
    if name.nil?
      @data[:name]  = File.basename File.split(@PROJECT_PATH)[0]
    else
      error "FILE \"#{project_path}\" does not exist!"
    end

    ## opening the project file
    begin
      @raw_data        = YAML::load(File.open(project_path))
    rescue SyntaxError => error
      warn "error parsing #{project_path}"
      puts error
      @STATUS = :unparsable
      return false
    else
      @data[:valid] = true # at least for the moment
      @data[:project_path]  = project_path
    end

    #load format and transform or not
    @data[:format] = @raw_data['format'] ? @raw_data['format'] : "1.0.0"
    if @data[:format] < "2.4.0"
      @raw_data = import_100 @raw_data
    end

    prepare_data()
    return true
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
      { old:"signature",    new:"manager"           }, #trim
      #{ old:"hours/time",  new:"hours/total"       },
    ]
    ht = HashTransform.new :rules => rules, :original_hash => hash
    new_hash = ht.transform()

    date = strpdates(hash['date'])
    new_hash.set("event/dates/0/begin", date[0])
    new_hash.set("event/dates/0/end",   date[1]) unless date[1].nil?
    new_hash.set("event/dates/0/time/begin", new_hash.get("time"))     if date[1].nil?
    new_hash.set("event/dates/0/time/end",   new_hash.get("time_end")) if date[1].nil?

    if new_hash.get("client/fullname").class == String and
    new_hash.get("client/fullname").words.class == Array
      new_hash.set("client/title", new_hash.get("client/fullname").words[0])
      new_hash.set("client/last_name", new_hash.get("client/fullname").words[1])
    else
      fail_at :client_fullname
    end
    new_hash.set("offer/date", Date.today)
    new_hash.set("invoice/date", Date.today)

    return hash
  end


  def prepare_data
    @@known_keys.each {|key| read key }
    @@dynamic_keys.each {|key|
      value = apply_generator key, @data
      @data.set key, value, ?_, true # symbols = true
    }
  end

  def validate choice = :invoice
    (invalidators = { # self explaiatory ain't it? :D
      :invoice   => [:invoice_number, :products],
      :offer     => [:offer_number]
    }[choice] & @ERRORS).length==0
  end

  def to_s
    name
  end

  def to_yaml
    @raw_data.to_yaml
  end


  def name
    @data[:canceled] ? "CANCELED: #{@data[:name]}" : @data[:name]
    @data[:name]
  end

  def date
    @data[:event][:date] if @data[:event]
  end

  def export_filename choice, ext=""
    offer_number = @data[:offer_number]
    invoice_number = @data[:invoice_number]
    name = @data[:name]
    date = @data[:date].strftime "%Y-%m-%d"

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
    :total_invoice, :cost_offer, :cost_invoice, :cost_offer, :tax_invoice, :tax_offer,
    :price

  def initialize(hash, tax_value = $SETTINGS['defaults']['tax'])
    @hash      = hash
    @name      = hash[:name]
    @price     = hash[:price]
    @amount    = hash[:amount]
    @tax_value = tax_value
    fail "TAX MUST NOT BE > 1" if @tax_value > 1


    @valid = true
    calculate() unless hash.nil?
  end

  def to_s
    "#{@amount}|#{@sold} #{@name}, #{@price} cost (#{@cost_offer}|#{@cost_invoice}) total(#{@total_offer}|#{@total_invoice}) "
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
end
