# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/InvoiceProduct.rb'
require 'yaml'
class InvoiceProject

  attr_reader :path , :data, :raw_data, :errors

  def initialize(settings, path = nil)
    # expecting to find in settings
    #   @settings['templates']= {}
    #   @settings['templates']['invoice']
    #   @settings['templates']['offer']

    @settings = settings
    @errors = []
    
    parse(path) unless path.nil?

    #fail_at :template_offer   unless File.exists? @settings['templates']['offer']
    #fail_at :template_invoice unless File.exists? @settings['templates']['invoice']
    #load_templates()

    @data            = {}
    @requirements = {
      :display => [:date, :name, :manager],
      :offer => [ :hours,
                  :offer_number,
                  :address,
                  :message,
                  :time,
                  :salary_total ],
      :invoice=> [:invoice_number,:caterers],
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
  # run validate() to initiate all parser functions.
  # If strikt = true the programm fails, otherise it returns false,
  def validate(type)
    @requirements[type].each { |criterion|
      return false if @errors.include? criterion
    }
  end


  ##
  # wrapper for @data
  # TODO rename this function InvoiceProject#get(:type)
  def read type
    return @data[type]
  end

  #def mine key, data
  #  matches = {
  #    :invoice_number = [data['rnumber'], data['invoice_number']],
  #    :offer_number = [data['anumber'], data['offer_number']],
  #  }
  #end

  ## open given .yml and parse into @data
  def parse(path)
    @path = path

    if File.exists?(path)
      begin
        @raw_data        = YAML::load(File.open(path))
      rescue
        logs "error reading #{path}"
      end
      @data[:valid]   = true
      @data[:path]    = path
      @data[:name]    = File.basename(path, @settings['project_file_extension'])
      @data[:tax]     = @raw_data['tax']?  @raw_data['tax']  : @settings['default_tax']
      @data[:lang]    = @raw_data['lang']? @raw_data['lang'] : @settings['default_lang']
      @data[:lang]    = @data[:lang].to_sym

      # TODO parse event, address and message as well as tax

      parse_simple :event
      parse_simple :address
      parse_simple :message
      parse_client    @raw_data
      parse_email     @raw_data
      parse_date      @raw_data
      parse_signature @raw_data
      parse_numbers   @raw_data
      parse_hours     @raw_data
      parse_products  @raw_data

      return @raw_data
    else fail_at :path
    end
    return false
  end

  def parse_simple key
    return fail_at key unless @raw_data[key.to_s]
    @data[key] = @raw_data[key.to_s]
  end

  ##
  # takes raw_data
  # manipulates @data
  # returns true or false
  def parse_products(raw_data)
    return fail_at :products unless @raw_data['products']
    tax_value                 = @data[:tax]
    @data[:products]         = {}

    @raw_data['products'].each { |p|
      name = p[0]
      hash = p[1]
      product = InvoiceProduct.new(name, hash, @data[:tax])
      @data[:products][name] = product
      return fail_at :products unless product.valid
    }

    return true
  end

  def get_cost type
    sum = 0.0
    read(:products).each {|name,product|
      fail_at "products_#{name}".to_sym unless product.valid
        sum += product.cost type
    }
    return sum.to_euro
  end

  ##
  # takes raw_data
  # manipulates @data
  # returns true or false
  def parse_numbers(raw_data)
    unless @data[:date]
      @data[:date] = Date.today
      return fail_at :offer_number
    end
    year =  @data[:date].year
    @data[:numbers] ={}

    # optional invoice_number
    if @raw_data['rnumber'].nil? 
      @data[:invoice_number] = ''
      fail_at :invoice_number
    else
      @data[:numbers][:invoice_long] = "R#{year}-%03d" % @raw_data['rnumber']
      @data[:numbers][:invoice_long] = "R#{year}-%03d" % @raw_data['rnumber']
      @data[:numbers][:invoice_short] = "R%03d" % @raw_data['rnumber']
    end

    if @raw_data['anumber'].nil?
      @data[:numbers][:offer] = @raw_data['manumber']
    else
      @data[:numbers][:offer] = Date.today.strftime "A%Y%m%d-" + @raw_data['anumber'].to_s
    end
    return true
  end

  ##
  # takes raw_data
  # manipulates @data
  # returns true or false
  def parse_client(raw_data)
    return fail_at :client unless @raw_data['client']

    names = @raw_data['client'].split("\n")
    titles = @raw_data['client'].split("\n")
    titles.pop()
    @data[:client] = {}
    @data[:client][:last_name] = names.last
    @data[:client][:titles] = titles.join ' '
    addressing = client_addressing()
    @data[:client][:addressing] = [
      addressing,
      @data[:client][:titles],
      @data[:client][:last_name]
    ].join ' '
    return true
  end

  def parse_email(raw_data)
    return fail_at :email unless raw_data['email'] =~ $RFC5322
    @data[:email] = raw_data['email']
  end

  ##
  # takes raw_data
  # manipulates @data
  # returns true or false
  def parse_date(raw_data)
    #reading date
    return fail_at :date unless raw_data['date']
    begin
      @data[:date]    = strpdates(raw_data['date'])[0]
      @data[:date_end] = strpdates(raw_data['date'])[1]
      #puts @data
      return true
    rescue
      return false
    end
  end

  ##
  # takes raw_data
  # manipulates @data
  # returns true or false
  def parse_signature(raw_data)
    return fail_at [:signature,:manager] if @raw_data['signature'].nil?
    lines = @raw_data['signature'].split("\n").to_a

    if lines.length > 1
      @data[:caterer] = lines.last
      @data[:signature] = lines.join "\n"
    else
      @data[:caterer] = lines.first
      @data[:signature] = @data[:caterer]
    end
    return true
  end


  def client_addressing
    names = @raw_data['client'].split("\n")
    type = names.first.downcase.to_sym
    gender = @gender_matches[type]
    lang = @data[:lang].to_sym
    return @lang_addressing[lang][gender]
  end

  ##
  # takes raw_data
  # manipulates @data
  # returns true or false
  def parse_hours(raw_data)
    @data[:hours]          = raw_data['hours']
    @data[:hours][:time]   = @raw_data['hours']['time']
    salary = @raw_data['hours']['salary']
    @data[:salary_total]   = salary * @data[:hours][:time]

    return fail_at :hours  unless @data[:hours]
    return fail_at :time   unless @data[:hours][:time]
    return fail_at :salary unless @data[:salary_total].class == Float
    return true            unless @data[:hours][:caterers] # for old projects


    sum = 0.0
    caterers   = @raw_data['hours']['caterers']

    @data[:hours][:caterers].values.each {|v| sum+=v}

    @data[:hours][:sum]    = sum
    @data[:salary][:sum]   = @data[:hours][:sum] * @data[:salary][:value]
    raw_data['hours']['caterers'].each{|k,v| @data[:salary][:caterers][k] = v*salary}

   
    return (sum == @data[:hours]['time'])
  end

  ##
  # *wrapper* for puts()
  # depends on settings['verbose']= true|false
  def logs message, force = false
    puts "       #{__FILE__} : #{message}" if @settings['verbose'] or force
  end

  #def tex_product_table
  #  table = ""
  #  @data[:products].each do |name, p|
  #    table += "#{name.ljust(20)} & #{p['sold']} & #{p['price'].to_euro} & #{p['sum_offered'].to_euro.to_s.rjust(6)} \\\\\ \n"
  #    table += "#{name.ljust(20)} & #{p['amount']} & #{p['price'].to_euro} & #{p['sum_invoiced'].to_euro.to_s.rjust(6)} \\\\\ \n"
  #  end
  #  return table
  #end

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

  def fail_at(criterion)
    if criterion.class == Hash
      criterion.each  {|c|
        fail_at c
      }
      return false
    else
      @errors.push criterion unless @errors.include? criterion
      return false
    end
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
