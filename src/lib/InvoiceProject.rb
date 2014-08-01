# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/ProjectFileReader.rb'
require File.join File.dirname(__FILE__) + '/Filters.rb'
require File.join File.dirname(__FILE__) + '/Euro.rb'
require File.join File.dirname(__FILE__) + '/texwriter.rb'
require 'yaml'

## TODO requirements and validity
## TODO open, parse, [transform, ] read_all, validate
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

  @@known_keys=
    [:format, :created, :client,
     :event,
     :offer,
     :invoice,
     :messages,
     :products,
     :hours,
     :manager]

  def initialize(settings, project_path = nil, name = nil)
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

    if File.exists?(project_path)
      if name.nil?
        @data[:name]  = File.basename File.split(@PROJECT_PATH)[0]
      else
        @data[:name] = name
      end

      begin
        @raw_data        = YAML::load(File.open(project_path))
      rescue SyntaxError => error
        warn "error parsing #{project_path}"
        puts error

        @STATUS = :unparsable
      else

        @data[:valid] = true # at least for the moment
        @data[:project_path]  = project_path

        return @raw_data
      end

    else
      error "FILE \"#{project_path}\" does not exist!"

    end
    return false
  end

  def prepare_data
    @@known_keys.each {|key| read key }
  end


  def name
    @data[:canceled] ? "CANCELED: #{@data[:name]}" : @data[:name]
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
    :cost_invoice, :cost_offer, :tax_invoice, :tax_offer, :price

  def initialize(hash, tax_value = $SETTINGS['defaults']['tax'])
    @hash      = hash
    @name      = hash[:name]
    @tax_value = tax_value

    @valid = true
    validate() unless hash.nil?
  end

  def validate()
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

    calculate()
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
    return @tax_offer   if choice == :offer
    return @tax_invoice if choice == :invoice
  end

  def calculate()
    @cost_invoice = (@price * @sold).to_euro
    @cost_offer   = (@price * @amount).to_euro

    @tax_invoice  = (@cost_invoice * @tax_value)
    @tax_offer    = (@cost_offer   * @tax_value)
  end

  #TODO implement InvoiceProduct.+()
  def + other
    {
      :amount_offer   => self.amount(  :offer   ) + other.amount(  :offer   ) ,
      :amount_invoice => self.amount(  :invoice ) + other.amount(  :invoice ) ,
      :cost_offer     => self.cost(    :offer   ) + other.cost(    :offer   ) ,
      :cost_invoice   => self.cost(    :invoice ) + other.cost(    :invoice ) ,
      :tax_offer      => self.tax(     :offer   ) + other.tax(     :offer   ) ,
      :tax_invoice    => self.tax(     :invoice ) + other.tax(     :invoice ) ,
    }
  end

end
