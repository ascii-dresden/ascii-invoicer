# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require 'yaml'
class Invoicer

  attr_reader :project_file, :project_data

  def initialize(settings)
    # expecting to find in settings
    #   @settings['templates']= {}
    #   @settings['templates']['invoice']
    #   @settings['templates']['offer']
    
    @settings = settings

    check_offer_template   = File.exists? @settings['templates']['offer']
    check_invoice_template = File.exists? @settings['templates']['invoice']

    load_templates()
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


  end

  ## open given .yml and parse into @data
  def load_project(path)
    @project_file = path

    if File.exists?(path)
      begin
        @raw_project_data = YAML::load(File.open(path))
        @project_data = {}
        @project_data['lang'] = @raw_project_data['lang'].to_sym
        @project_data['tax'] = @raw_project_data['tax']? @raw_project_data['tax'] : 1.19
        @project_data['name'] = File.basename path, '.'+@settings['project_file_extension']
      rescue
        logs "error reading #{path}"
      end
      
      #pp @project_data
      return @raw_project_data
    end
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

  ##
  def validate()
    return false if @raw_project_data.nil?

    #address
    #signature
    #message
    #email

    
    return false unless parse_project_client    @raw_project_data
    return false unless parse_project_email     @raw_project_data
    return false unless parse_project_date      @raw_project_data
    return false unless parse_project_numbers   @raw_project_data
    return false unless parse_project_hours     @raw_project_data
    return false unless parse_project_products  @raw_project_data
    return false unless parse_project_signature @raw_project_data
    return true
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_client(raw_project_data)
    return false unless @raw_project_data['client']
    names = @raw_project_data['client'].split("\n")
    titles = @raw_project_data['client'].split("\n")
    titles.pop()
    @project_data['client'] = {}
    @project_data['client']['last_name'] = names.last
    @project_data['client']['titles'] = titles.join ' '
    addressing = client_addressing()
    @project_data['client']['addressing'] = [
      addressing,
      @project_data['client']['titles'],
      @project_data['client']['last_name']
    ].join ' '
    return true
  end

  def parse_project_email(raw_project_data)
    return true if raw_project_data['email'].nil?
    return false unless raw_project_data['email'] =~ $RFC5322
    @project_data['email'] = raw_project_data['email']
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_date(raw_project_data)
    #reading date
    return false unless raw_project_data['date']
    begin
      @project_data['date']    = strpdates(raw_project_data['date'])[0]
      @project_data['date_end'] = strpdates(raw_project_data['date'])[1]
      #puts @project_data
      return true
    rescue
      return false
    end
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_signature(raw_project_data)
    return false unless @raw_project_data['signature']
    @project_data['signature'] = @raw_project_data['signature'].chop
    @project_data['caterer'] = @project_data['signature'].split("\n").last
    return true
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_products(raw_project_data)
    return false unless @raw_project_data['products']
    tax                               = @project_data['tax']
    @project_data['products']         = {}
    @project_data['products']['list'] = {}
    @project_data['products']['sums'] = {}
    sum_offered                       = 0.0
    sum_invoiced                      = 0.0
    sum_offered_tax                   = 0.0
    sum_invoiced_tax                  = 0.0

    @raw_project_data['products'].each{|p|
      return false unless p[1] # no block within products

      name     = p[0]
      return false if @project_data['products']['list'].keys.include? name

      amount   = p[1]['amount']
      sold     = p[1]['sold']
      price    = p[1]['price']
      returned = p[1]['returned']
      return false unless amount and   price
      return false unless sold.nil? or returned.nil?

      if sold
        sold = sold
        p[1]['returned'] = amount - sold
      elsif returned
        sold = amount - returned
        p[1]['sold'] = sold
      else
        sold = amount
        p[1]['sold'] = amount
      end

      product_sum_offered  = p[1]['sum_offered']  = (amount * price).ceil_up()
      product_sum_invoiced = p[1]['sum_invoiced'] = (sold * price).ceil_up()


      sum_offered      += product_sum_offered
      sum_invoiced     += product_sum_invoiced
      sum_offered_tax  += product_sum_offered
      sum_invoiced_tax += product_sum_invoiced

      #puts "#{name} : #{sum_offered} -> #{sum_invoiced}"

      @project_data['products']['list'][name] = p[1]
    }

    sum_offered_tax       = (tax * sum_offered_tax).ceil_up()
    sum_invoiced_tax      = (tax * sum_invoiced_tax).ceil_up()
    sum_offered_tax_only  = (sum_offered_tax  - sum_offered).ceil_up()
    sum_invoiced_tax_only = (sum_invoiced_tax - sum_invoiced).ceil_up()

    @project_data['products']['sums']['offered']           = sum_offered
    @project_data['products']['sums']['invoiced']          = sum_invoiced
    @project_data['products']['sums']['offered_tax']       = sum_offered_tax
    @project_data['products']['sums']['invoiced_tax']      = sum_invoiced_tax
    @project_data['products']['sums']['offered_tax_only']  = sum_offered_tax_only
    @project_data['products']['sums']['invoiced_tax_only'] = sum_invoiced_tax_only
    return true
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_numbers(raw_project_data)
    year =  @project_data['date'].year
    @project_data['numbers'] ={}
    # optional Rechnungsnummer
    if @raw_project_data['rnumber'].nil? 
      @project_data['invoice_number'] = ''
    else
      @project_data['numbers']['invoice_long'] = "R#{year}-%03d" % @raw_project_data['rnumber']
      @project_data['numbers']['invoice_short'] = "R%03d" % @raw_project_data['rnumber']
    end

    if @raw_project_data['anumber'].nil?
      @project_data['numbers']['offer'] = @raw_project_data['manumber']
    else
      @project_data['numbers']['offer'] = Date.today.strftime "A%Y%m%d-" + @raw_project_data['anumber'].to_s
    end
    return true
  end

  def client_addressing
    names = @raw_project_data['client'].split("\n")
    sym = names.first.downcase.to_sym
    gender = @gender_matches[sym]
    lang = @raw_project_data['lang'].to_sym
    return @lang_addressing[lang][gender]
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_hours(raw_project_data)
    @project_data['hours'] = raw_project_data['hours']

    return false unless @project_data['hours']
    return false unless @project_data['hours']['salary'].class == Float
    return false unless @project_data['hours']['time']
    return true  unless @project_data['hours']['caterers']

    sum = 0
    salary = @project_data['hours']['salary']

    @project_data['hours']['caterers'].values.each {|v| sum+=v}

    @project_data['hours']['sum']    = sum
    @project_data['hours']['sum']    = sum
    @project_data['salary'] = {}
    @project_data['salary']['value'] = @raw_project_data['hours']['salary']
    @project_data['salary']['sum']   =
      @project_data['hours']['sum'] * @project_data['salary']['value']
    @project_data['salary']['caterers']= {}
    raw_project_data['hours']['caterers'].each{|k,v| @project_data['salary']['caterers'][k] = v*salary}

   
    return (sum == @project_data['hours']['time'])
  end

  def print_data(key = nil)
    if key
      pp @project_data[key.to_s]
    else
      pp @project_data
    end
  end

  ##
  # *wrapper* for puts()
  # depends on settings['verbose']= true|false
  def logs message, force = false
    puts "       #{__FILE__} : #{message}" if @settings['verbose'] or force
  end

  def tex_product_table
    table = ""
    @project_data['products']['list'].each_pair do |name, p|
      table += "#{name.ljust(20)} & #{p['sold']} & #{p['price'].to_euro} & #{p['sum_offered'].to_euro.to_s.rjust(6)} \\\\\ \n"
      table += "#{name.ljust(20)} & #{p['amount']} & #{p['price'].to_euro} & #{p['sum_invoiced'].to_euro.to_s.rjust(6)} \\\\\ \n"
    end
    return table
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
end

class Float
  def ceil_up
    n = self
    n = n*100
    n = n.round().to_f()
    n = n/100
    return n
  end

  def to_euro
    a,b = sprintf("%0.2f", self.to_s).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    "#{a},#{b}€"
  end
end
