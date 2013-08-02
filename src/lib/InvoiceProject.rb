# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/module_parsers.rb'
require 'yaml'
class InvoiceProject
  attr_reader :path , :data, :raw_data, :errors, :valid_for
  attr_writer :raw_data, :errors

  include InvoiceParsers

  def initialize(settings, path = nil)
    @settings = settings
    @errors   = []
    @data     = {}

    open(path) unless path.nil?

    #fail_at :template_offer   unless File.exists? @settings['templates']['offer']
    #fail_at :template_invoice unless File.exists? @settings['templates']['invoice']
    #load_templates()

    @gender_matches = {
      :herr => :male,
      :frau => :female,
      :professor => :male,
      :professorin => :female
    }
    @lang_addressing = {
      :de => {
        :male   => "Sehr geehrter",
        :female => "Sehr geehrte"
      },
      :en => {
        :male   => "Dear",
        :female => "Dear"
      }, }

    @requirements = {
      :display => [
                    :tax, :date, :manager, :name
      ],
      :offer   => [
                    :tax, :date, :manager, :name,
                    :hours, :time, :salary_total, 
                    :address, :message, :event, :signature,
                    :offer_number, :costs,
                    :caterers
                  ],
      :invoice => [
                    :tax, :date, :manager, :name,
                    :hours, :time, :salary_total, 
                    :address, :message, :event, :signature,
                    :offer_number, :costs,
                    :invoice_number, :invoice_number_long,
                    :caterers
                  ],
      :full    => [ 
                    :tax, :date, :manager, :name,
                    :hours, :time, :salary_total, 
                    :address, :message, :event, :signature,
                    :offer_number, :costs,
                    :invoice_number, :invoice_number_long,
                    :caterers
                  ],
    }

    # TODO turn blub_invoice or blub_offer into blub(:offer)
    # TODO allow for alternatives
    @parser_matches = {
      #:key                => [parser,            parameters]
      :date_end            => [:parse_date,       :end],
      :manager             => [:parse_signature,  :manager],
      :offer_number        => [:parse_numbers,    :offer],
      :invoice_number      => [:parse_numbers,    :invoice],
      :invoice_number_long => [:parse_numbers,    :invoice_long],
      :address             => [:parse_simple,     :address],
      :message             => [:parse_simple,     :message],
      :event               => [:parse_simple,     :event],
      :tax                 => [:parse_simple,     :tax ],
      :time                => [:parse_hours,      :time],
      :caterers            => [:parse_hours,      :caterers],
      :salary_total        => [:parse_hours,      :salary_total],
    }

    @parser_matches.each {|k,v| 
      begin 
        m = method v[0] 
      rescue
        puts "ERROR in parser_matches: #{v[0]} is no method"
        exit
      end
      }
  end

  ## open given .yml and parse into @data
  def open(path)
    @path = path

    if File.exists?(path)
      begin
        @raw_data        = YAML::load(File.open(path))
      rescue
        logs "error reading #{path}"
      end

      @data[:valid] = true
      @data[:path]  = path
      @data[:name]  = File.basename File.split(@path)[0]
      #@data[:tax]  = @raw_data['tax']?  @raw_data['tax']  : @settings['default_tax']

      @data[:lang]  = @raw_data['lang']? @raw_data['lang'] : @settings['default_lang']
      @data[:lang]  = @data[:lang].to_sym


      return @raw_data
    else fail_at :path
    end
    return false
  end

  ##
  # run validate() to initiate all parser functions.
  # If strikt = true the programm fails, otherise it returns false,
  def validate(type)
    @data[:type] = type
    @valid_for = {}
    @requirements[type].each { |req| parse req }
    @requirements.each { |type, requirements|
      @valid_for[type] = true
      requirements.each { |req|
        @valid_for[type] = false unless @data[req] 
      }
    }
  end


  ## little parse function
  def parse(key, parser = "parse_#{key}", parameter = nil)
    #pp "parsing: #{key}"
    return @data[key] if @data[key]
    begin
      parser = method parser
    rescue
      if @parser_matches.keys.include? key
        pm = @parser_matches[key]
        return fail_at key unless pm[0] or pm[1]
        parse(key, pm[0], pm[1])
        return @data[key]
      else
        @data[key] = false
        return fail_at key
      end
    end

    unless parameter.nil?
      @data[key] = parser.call(parameter)
    else
      @data[key] = parser.call() 
    end
    return @data[key]
  end

  def parse_simple key
    raw     = @raw_data[key.to_s]
    default = $SETTINGS["default_#{key.to_s}"]
    return raw     if raw
    return default if default
    return fail_at key
  end


  ##
  # *wrapper* for puts()
  # depends on settings['verbose']= true|false
  def logs message, force = false
    puts "       #{__FILE__} : #{message}" if @settings['verbose'] or force
  end

  def tex_product_table
    table = ""
    @data[:products].each do |name, p|
      table += "#{name.ljust(20)} & #{p['sold']} & #{p['price'].to_euro} & #{p['sum_offered'].to_euro.to_s.rjust(6)} \\\\\ \n"
      table += "#{name.ljust(20)} & #{p['amount']} & #{p['price'].to_euro} & #{p['sum_invoiced'].to_euro.to_s.rjust(6)} \\\\\ \n"
    end
    return table
  end

  def client_addressing
    names = @raw_data['client'].split("\n")
    type = names.first.downcase.to_sym
    gender = @gender_matches[type]
    lang = @data[:lang].to_sym
    return @lang_addressing[lang][gender]
  end

  def strpdates(string,pattern = nil)
    if pattern 
      return [Date.strptime(string, pattern).to_date]
    else
      p = string.split('.')
      p_range = p[0].split('-')

      if p_range.length == 1
        t = Date.new p[2].to_i, p[1].to_i, p[0].to_i
        return [t]

      elsif p_range.length == 2
        t1 = Date.new p[2].to_i, p[1].to_i, p_range[0].to_i
        t2 = Date.new p[2].to_i, p[1].to_i, p_range[1].to_i
        return [t1,t2]

      else
        fail
      end
    end
  end

  def fail_at(*criteria)
    @data[:valid] = false
    criteria.each  {|c|
      @errors.push c unless @errors.include? c
    }
    return false
  end

  ##
  # loads template files named in settings
  def load_templates()
    offer   = @settings['templates']['offer']
    invoice = @settings['templates']['invoice']
    if File.exists?(offer) and File.exists?(invoice)
      @template_offer   = File.open(offer).read
      @template_invoice = File.open(invoice).read
      return true
    end
    return false
  end
end

class InvoiceProduct
  attr_reader :name, :hash, :tax, :valid, :returned, :cost_invoice, :cost_offer, :tax_invoice, :tax_offer

  def initialize(name, hash, tax_value)
    @name = name
    @h = hash
    @tax_value = tax_value

    @valid = true
    validate()
  end

  def validate()
    @valid    = false if @h.nil?
    @valid    = false unless @h['sold'].nil? or @h['returned'].nil?
    @valid    = false unless @h['amount'] and @h['price']
    @sold     = @h['sold']
    @price    = @h['price']
    @amount   = @h['amount']
    @returned = @h['returned']

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

  def calculate()
    @cost_invoice = (@sold   * @price).ceil_up()
    @cost_offer   = (@amount * @price).ceil_up()

    @tax_invoice  = (@cost_invoice * @tax_value).ceil_up()
    @tax_offer    = (@cost_offer   * @tax_value).ceil_up()
  end
end

class Object
  def ceil_up
    return self unless self.class == Float
    n = self
    n = n*100
    n = n.round().to_f()
    n = n/100
    return n
  end

  def to_euro(rj = -1)
    return self unless self.class == Float
    a,b = sprintf("%0.2f", self.to_s).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    if rj > 0
    "#{a},#{b}€".rjust rj
    else
    "#{a},#{b}€"
    end

  end
end
