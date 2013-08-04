# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/module_parsers.rb'
require 'yaml'
class InvoiceProject
  attr_reader :project_path, :project_folder, :data, :raw_data, :errors, :valid_for
  attr_writer :raw_data, :errors

  include InvoiceParsers

  def initialize(settings, project_path = nil)
    @settings = settings
    @errors   = []
    @data     = {}

    open(project_path) unless project_path.nil?

    #fail_at :template_offer   unless File.exists? @settings['templates']['offer']
    #fail_at :template_invoice unless File.exists? @settings['templates']['invoice']

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
      :list    => [ :tax, :date, :manager, :name, :offer_number, :invoice_number ],
      :offer   => [ :tax, :date, :manager, :name, :hours, :time, :salary_total, 
                    :event, :signature,
                    :costs_offer, :taxes_offer, :total_offer,
                    :offer_number,
                    :address, :messages, :client,
                    :tex_table_offer, :caterers,
                    :script_path
                  ],
      :invoice => [ :tax, :date, :manager, :name, :hours, :time, :salary_total, 
                    :event, :signature,
                    :costs_invoice, :taxes_invoice, :total_invoice,
                    :offer_number, :invoice_number, :invoice_number_long,
                    :address, :messages, :client,
                    :tex_table_invoice, :caterers,
                    :script_path
                  ],
      :full    => [ :tax, :date, :manager, :name, :hours, :time, :salary_total, 
                    :address, :messages, :event, :signature, :offer_number, :costs,
                    :costs_offer, :taxes_offer, :total_offer,
                    :costs_invoice, :taxes_invoice, :total_invoice,
                    :offer_number, :invoice_number, :invoice_number_long,
                    :tex_table, :caterers,
                  ],
      :export  => [ :tax, :date, :manager, :name, :hours, :time, :salary_total, 
                    :address, :event, :offer_number, :costs,
                    :invoice_number, :invoice_number_long, :caterers,
      ],
    }

    # TODO allow for alternative parser_matches
    @parser_matches = {
      #:key                => [parser,            parameters    ]
      :date_end            => [:parse_date,       :end          ] ,
      :manager             => [:parse_signature,  :manager      ] ,
      :offer_number        => [:parse_numbers,    :offer        ] ,
      :invoice_number      => [:parse_numbers,    :invoice      ] ,
      :invoice_number_long => [:parse_numbers,    :invoice_long ] ,
      :address             => [:parse_simple,     :address      ] ,
      :event               => [:parse_simple,     :event        ] ,
      :tax                 => [:parse_simple,     :tax          ] ,

      :costs_offer         => [:parse_costs,      :offer        ] ,
      :costs_invoice       => [:parse_costs,      :invoice      ] ,
      :taxes_offer         => [:parse_taxes,      :offer        ] ,
      :taxes_invoice       => [:parse_taxes,      :invoice      ] ,
      :total_offer         => [:parse_total,      :offer        ] ,
      :total_invoice       => [:parse_total,      :invoice      ] ,

      :tex_table_invoice   => [:parse_tex_table,  :invoice      ] ,
      :tex_table_offer     => [:parse_tex_table,  :offer        ] ,
      :time                => [:parse_hours,      :time         ] ,
      :caterers            => [:parse_hours,      :caterers     ] ,
      :salary_total        => [:parse_hours,      :salary_total ] ,
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
  def open(project_path)
    #puts "opening \"#{project_path}\""
    @project_path = project_path
    @project_folder = File.split(project_path)[0]

    if File.exists?(project_path)
      begin
        @raw_data        = YAML::load(File.open(project_path))
      rescue
        logs "error reading #{project_path}"
      end

      @data[:valid] = true
      @data[:project_path]  = project_path
      @data[:name]  = File.basename File.split(@project_path)[0]

      @data[:lang]  = @raw_data['lang']? @raw_data['lang'] : @settings['default_lang']
      @data[:lang]  = @data[:lang].to_sym


      return @raw_data
    else
      fail_at :project_path
      error "FILE \"#{project_path}\" does not exist!"
    end
    return false
  end

  ##
  # run validate() to initiate all parser functions.
  # If strikt = true the programm fails, otherise it returns false,
  def validate(type)
    return true if @data[:type] == type and @data[:valid]
    @data[:type] = type
    @valid_for = {}
    @requirements[type].each { |req| parse req }
    @requirements.each { |type, requirements|
      @valid_for[type] = true
      requirements.each { |req|
        @valid_for[type] = false unless @data[req] 
      }
    }
    return true if @data[:valid]
    false
  end

  ##
  # little parse function
  def parse(key, parser = "parse_#{key}", parameter = nil)
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
    offer   = File.join $SETTINGS['script_path'], $SETTINGS['templates']['offer']
    invoice = File.join $SETTINGS['script_path'], $SETTINGS['templates']['invoice']
    if File.exists?(offer) and File.exists?(invoice)
      @template_invoice = File.open(invoice).read
      @template_offer   = File.open(offer).read
      return true
    end
    return false
  end


  def export_filename choice, ext=""
    offer_number = @data[:offer_number]
    invoice_number = @data[:invoice_number]
    name = @data[:name]
    date = @data[:date].strftime "%Y-%m-%d"

    ext = '.' + ext unless ext.length > 0 and ext.start_with? '.'

    if choice == :invoice
      "#{invoice_number} #{name} #{date}#{ext}"
    elsif choice == :offer
      "#{offer_number} #{name}#{ext}"
    else
      return false
    end
  end

  ##
  # fills the template with minded data
  def create_tex choice, check = false
    return fail_at :create_tex unless parse :products
    return fail_at :templates unless load_templates()

    puts $SETTINGS['path']
    puts $SETTINGS['script_path']
    puts export_filename choice, "tex"
    return

    template = @template_invoice if choice == :invoice
    template = @template_offer   if choice == :offer

    table = CliTable.new 
    table.header = "Template matches"

    template.each_line { |line| 
      if check
        scans = line.scan /\$([^$]*)\$/
        if scans.length > 0
          findings = scans.map{|s| not @data[s[0].to_sym].nil? and not @data[s[0].to_sym] == false  }
          table.add_row [scans.flatten.join(", "), findings.join(','),]
        end
      else
        @data.keys.each{ |key| line = line.gsub('$' + key.to_s + '$', @data[key].to_s) }
        puts line
      end
    }

    puts table if check
  end
end

class InvoiceProduct
  attr_reader :name, :hash, :tax, :valid, :returned, :cost_invoice, :cost_offer, :tax_invoice, :tax_offer, :price

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

  def amount choice
    return @sold   if choice == :invoice
    return @amount if choice == :offer
    return -1
  end

  def cost choice
    return cost_invoice.to_euro if choice == :invoice
    return cost_offer.to_euro   if choice == :offer
    return -1.to_euro
  end

  def calculate()
    @cost_invoice = (@sold   * @price).ceil_up()
    @cost_offer   = (@amount * @price).ceil_up()

    @tax_invoice  = (@cost_invoice * @tax_value).ceil_up()
    @tax_offer    = (@cost_offer   * @tax_value).ceil_up()
  end
end
