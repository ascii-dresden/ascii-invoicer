# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/InvoiceProduct.rb'
require File.join File.dirname(__FILE__) + '/invoiceParsers.rb'
require 'yaml'
class InvoiceProject

  attr_reader :path , :data, :errors
  attr_writer :raw_data, :errors

  include InvoiceParsers

  def initialize(settings, path = nil)
    # expecting to find in settings
    #   @settings['templates']= {}
    #   @settings['templates']['invoice']
    #   @settings['templates']['offer']

    @settings = settings
    @errors   = []
    @data     = {}
    @path     = path

    open(path) unless path.nil?

    #fail_at :template_offer   unless File.exists? @settings['templates']['offer']
    #fail_at :template_invoice unless File.exists? @settings['templates']['invoice']
    #load_templates()

    @requirements = {
      :display => [:date, :name, :manager],
      :offer => [ :hours, :offer_number, :address,
                  :message, :time, :salary_total ],
                  :invoice => [ :hours, :offer_number, :address,
                                :message, :time, :salary_total, :invoice_number,:caterers],
    }

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

    @parser_matches = {
      #:key => [key, parser, parameters]
      :date_end => [:parse_date, :end],
      :manager => [:parse_signature, :manager],
      :time => []
    }


    #parse :email
    #parse :date
    #parse :date_end
    #parse :hours
    #parse :numbers
    #parse :signature
    #parse :client
    #parse :products
    #parse :date_end,  :parse_date,       :end
    #parse :manager
    #parse :manager,   :parse_signature,  :manager
    #parse :event,     :parse_simple,     :event
    #parse :address,   :parse_simple,     :address
    #parse :message,   :parse_simple,     :message

  end

  ## little parse function
  def parse(key, parser = "parse_#{key}", parameter = nil)
    return if @data[:key]
    begin
      parser = method parser
    rescue
      if @parser_matches.keys.include? key
        pm = @parser_matches[key]
        return fail_at key unless pm[0] or pm[1]
        parse(key, pm[0], pm[1])
        return
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
  end

  ##
  # run validate() to initiate all parser functions.
  # If strikt = true the programm fails, otherise it returns false,
  def validate(type)
    @requirements[type].each { |req|
      parse req
      return false if @errors.include? req
    }
  end


  #def mine key, data
  #  matches = {
  #    :invoice_number = [data['rnumber'], data['invoice_number']],
  #    :offer_number = [data['anumber'], data['offer_number']],
  #  }
  #end

  ## open given .yml and parse into @data
  def open(path)
    @path = path

    if File.exists?(path)
      begin
        @raw_data        = YAML::load(File.open(path))
      rescue
        logs "error reading #{path}"
      end

      @data[:valid]   = true
      @data[:path]    = path
      #@data[:name]    = File.basename(path, @settings['project_file_extension'])
      #@data[:tax]     = @raw_data['tax']?  @raw_data['tax']  : @settings['default_tax']

      @data[:lang]    = @raw_data['lang']? @raw_data['lang'] : @settings['default_lang']
      @data[:lang]    = @data[:lang].to_sym


      return @raw_data
    else fail_at :path
    end
    return false
  end

  def get_cost type
    sum = 0.0
    @data[:products].each {|name,product|
      fail_at "products_#{name}".to_sym unless product.valid
      sum += product.cost type
    }
    return sum.to_euro
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
      @errors.push c unless @errors.include? criteria
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

class Object
  def ceil_up
    return self unless self.class == Float
    n = self
    n = n*100
    n = n.round().to_f()
    n = n/100
    return n
  end

  def to_euro
    return self unless self.class == Float
    a,b = sprintf("%0.2f", self.to_s).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    "#{a},#{b}€"
  end
end
