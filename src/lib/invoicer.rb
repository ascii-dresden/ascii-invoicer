# encoding: utf-8
require 'ostruct'

class Invoicer

  attr_reader :project_file, :project_data

  def initialize(settings)
    # expecting to find in settings
    #   @settings.template_files= {}
    #   @settings.template_files[:invoice]
    #   @settings.template_files[:offer]
    
    @settings = settings

    check_offer_template   = File.exists? @settings.template_files[:offer]
    check_invoice_template = File.exists? @settings.template_files[:invoice]

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
        @raw_project_data = OpenStruct.new YAML::load(File.open(path))
        @project_data = OpenStruct.new
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
    offer   = @settings.template_files[:offer]
    invoice = @settings.template_files[:invoice]
    if File.exists?(offer) and File.exists?(invoice)
      @template_offer   = File.open(offer).read
      @template_invoice = File.open(invoice).read
      return true
    end
    return false
  end

  ##
  def validate()
    return read_meta_data()
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_client(raw_project_data)
    return false unless @raw_project_data.client
    names = @raw_project_data.client.split("\n")
    titles = @raw_project_data.client.split("\n")
    titles.pop()
    @project_data.client = OpenStruct.new()
    @project_data.client.last_name = names.last
    @project_data.client.titles = titles.join ' '
    addressing = client_addressing()
    @project_data.client.addressing = [
      addressing,
      @project_data.client.titles,
      @project_data.client.last_name
    ].join ' '
    return true
  end

  def client_addressing
    names = @raw_project_data.client.split("\n")
    sym = names.first.downcase.to_sym
    gender = @gender_matches[sym]
    lang = @raw_project_data.lang.to_sym
    return @lang_addressing[lang][gender]

    #gender = @gender_matches[names.first]
    #return gender
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_date(raw_project_data)
    #reading date
    return false unless @raw_project_data.date
    begin
      @project_data.date    = strpdates(raw_project_data.date)[0]
      @project_data.date_end = strpdates(raw_project_data.date)[1]
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
    return false unless @raw_project_data.signature
    @project_data.signature = @raw_project_data.signature.chop
    @project_data.caterer = @project_data.signature.split("\n").last
    return true
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_products(raw_project_data)
    return false unless @raw_project_data.products
    @project_data.products = {}
    @raw_project_data.products.each{|p|
      return false unless p[1] # no block within products

      name     = p[0]
      return false if @project_data.products.keys.include? name

      amount   = p[1]['amount']
      sold     = p[1]['sold']
      price    = p[1]['price']
      returned = p[1]['returned']
      return false unless amount and   price
      return false unless sold.nil? or returned.nil?

      if sold
        final_amount = sold
      elsif returned
        final_amount = amount - returned
      else
        final_amount = amount
      end

      sum_offered = p[1]['sum_offered'] = (amount * price).ceil_up()
      sum_final   = p[1]['sum_final']   = (final_amount * price).ceil_up()

      #puts "#{name} : #{sum_offered} -> #{sum_final}"

      @project_data.products[name] = p[1]
    }
    return true
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_hours(raw_project_data)
    @project_data.hours = OpenStruct.new raw_project_data.hours
    return false unless @project_data.hours.salary.class == Float
    return false unless @project_data.hours.time
    return true unless @project_data.hours.caterers

    sum = 0
    salary = @project_data.hours.salary
    @project_data.hours.caterers.values.each {|v| sum+=v}
    @project_data.hours.sum = sum
    @project_data.hours.sum = sum
    @project_data.salary = OpenStruct.new
    @project_data.salary.sum = @project_data.hours.sum * @project_data.hours.salary
    @project_data.salary.caterers = raw_project_data.hours['caterers']
    #@project_data.salary.caterers.map!{|k,v| v+1}
    return (sum == @project_data.hours.time)
  end

  ##
  def read_meta_data()
    return false if @raw_project_data.nil?
    @project_data.lang = @raw_project_data.lang.to_sym

    client = parse_project_client @raw_project_data
    date   = parse_project_date   @raw_project_data
    hours  = parse_project_hours  @raw_project_data

    #return (date and hours and client)

    #address
    #client
    #addressing
    #offer_number
    #invoice_number
    #signature
    
    return (date and client and hours)

  end

  ##
  # *wrapper* for puts()
  # depends on @settings.silent = true|false
  def logs message, force = false
    puts "       #{__FILE__} : #{message}" unless @settings.silent and not force
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
