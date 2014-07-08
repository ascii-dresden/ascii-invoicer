# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/module_parsers.rb'
require 'yaml'

class InvoiceProject
  attr_reader :project_path, :project_folder, :data, :raw_data, :errors, :valid_for, :requirements
  attr_writer :raw_data, :errors

  include InvoiceParsers

  def initialize(settings, project_path = nil, name = nil)
    @settings = settings
    @errors   = []
    @data     = {}

    open(project_path, name) unless project_path.nil?

    #fail_at :template_offer   unless File.exists? @settings['templates']['offer']
    #fail_at :template_invoice unless File.exists? @settings['templates']['invoice']

    @gender_matches = {
      :herr        => :male,
      :frau        => :female,
      :professor   => :male,
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
      :list    => [ :canceled, :tax, :date, :date_end, :manager, :name, :offer_number, :invoice_number ],

      :offer   => [ :canceled,
                    :tax, :date, :date_end, :raw_date, :manager, :name,
                    :salary, :salary_total, :costs,
                    :costs_offer, :taxes_offer, :total_offer, :final_offer,
                    :offer_number,
                    :address, :messages,
                    :event, :signature, :addressing,
                    :tex_table_offer,
                    :script_path
                  ],
      :invoice => [ :canceled,
                    :tax, :date, :date_end, :raw_date, :manager, :name,
                    :salary, :salary_total, :costs,
                    :costs_invoice, :taxes_invoice, :total_invoice, :final_invoice,
                    :offer_number, :invoice_number, :invoice_number_long,
                    :address, :messages,
                    :event, :signature, :addressing,
                    :tex_table_invoice,
                    :script_path
                  ],
      :full    => [ :canceled,
                    :tax, :date, :date_end, :raw_date,
                    :time, :time_end, 
                    :manager, :name, :hours,
                    :salary, :salary_total,
                    :costs_offer,    :taxes_offer,    :total_offer,    :final_offer,
                    :costs_invoice,  :taxes_invoice,  :total_invoice,  :final_invoice,
                    :invoice_number, :invoice_number_long,
                    :address, :event, :offer_number, :costs,
                    :signature, :addressing,
                    :tex_table_offer, :tex_table_invoice,
                    :caterers, :messages, :request_message,:description, :script_path
                  ],
      :export  => [ :canceled,
                    :tax, :date, :date_end,
                    :manager, :name, :hours,
                    :time, :time_end,
                    :salary, :salary_total,
                    :costs_offer,    :taxes_offer,    :total_offer,    :final_offer,
                    :costs_invoice,  :taxes_invoice,  :total_invoice,  :final_invoice,
                    :invoice_number, :invoice_number_long,
                    :address, :event, :offer_number, :costs,
                    :invoice_number, :invoice_number_long,
                    :caterers, :request_message, :description
      ],
    }

    # TODO allow for alternative parser_matches
    @parser_matches = {
      #:key                => [parser,            parameters/key   ]
      :time_end            => [:parse_time,       :end             ] ,
      :date_end            => [:parse_date,       :end             ] ,
      :manager             => [:parse_signature,  :manager         ] ,
      :offer_number        => [:parse_numbers,    :offer           ] ,
      :invoice_number      => [:parse_numbers,    :invoice         ] ,
      :invoice_number_long => [:parse_numbers,    :invoice_long    ] ,
      :address             => [:parse_simple,     :address         ] ,
      :event               => [:parse_event,      :event           ] ,
      :tax                 => [:parse_simple,     :tax             ] ,
      :raw_date            => [:parse_simple,     :date            ] ,
      :description         => [:parse_simple,     :description     ] ,
      :request_message     => [:parse_simple,     :request_message ] ,
      :canceled            => [:parse_simple,     :canceled        ] ,

      :caterers            => [:parse_caterers,   :caterers        ] ,
      :costs_offer         => [:parse_costs,      :offer           ] ,
      :costs_invoice       => [:parse_costs,      :invoice         ] ,
      :taxes_offer         => [:parse_taxes,      :offer           ] ,
      :taxes_invoice       => [:parse_taxes,      :invoice         ] ,
      :total_offer         => [:parse_total,      :offer           ] ,
      :total_invoice       => [:parse_total,      :invoice         ] ,
      :final_offer         => [:parse_final,      :offer           ] ,
      :final_invoice       => [:parse_final,      :invoice         ] ,

      :tex_table_invoice   => [:parse_tex_table,  :invoice         ] ,
      :tex_table_offer     => [:parse_tex_table,  :offer           ] ,
      :hours               => [:parse_hours,      :time            ] ,
      :caterers            => [:parse_hours,      :caterers        ] ,
      :salary              => [:parse_hours,      :salary          ] ,
      :salary_total        => [:parse_hours,      :salary_total    ] ,
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
  def open(project_path, name = nil)
    #puts "opening \"#{project_path}\""
    raise "already opened another project" if @project_path
    @project_path = project_path
    @project_folder = File.split(project_path)[0]

    if File.exists?(project_path)
      begin
        @raw_data        = YAML::load(File.open(project_path))
      rescue
        error "error reading #{project_path}"
      end

      @data[:valid] = true # at least for the moment 
      @data[:project_path]  = project_path

      if name.nil?
        @data[:name]  = File.basename File.split(@project_path)[0]
      else @data[:name] = name
      end

      @data[:lang]  = @raw_data['lang']? @raw_data['lang'] : @settings['default_lang']
      @data[:lang]  = @data[:lang].to_sym

      return @raw_data

    else
      fail_at :project_path
      error "FILE \"#{project_path}\" does not exist!"
    end
    return false
  end

  def name
    @data[:canceled] ? "CANCELED: #{@data[:name]}" : @data[:name]
  end

  ##
  # run validate() to initiate all parser functions.
  # If strikt = true the programm fails, otherise it returns false,
  def validate(type, print = false)
    return true if @data[:type] == type and @data[:valid]
    @data[:type] = type
    @valid_for = {}
    @requirements[type].each { |req| parse req }
    @requirements.each { |type, requirements|
      @valid_for[type] = true
      puts type.to_s if print
      requirements.each { |req|
        puts "   " +
          (!@data[req].nil?).print + req.to_s.ljust(15) +
          "(#{ @data[req].to_s.each_line.first.to_s.each_line.first })" +
          "(#{@data[req].class})" if print
        if @data[req].nil?
          @valid_for[type] = false
          #@errors.push req unless @errors.include? req
        end
      }
      puts if print
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

      # look for mapping in @parser_matches
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
    if raw
      return raw.strip if raw.class == String
      return raw
    end
    return default if default
    return fail_at key
  end

  ##
  # *wrapper* for puts()
  # depends on settings['verbose']= true|false
  def logs message, force = false
    #puts "       #{__FILE__} : #{message}" if @settings['verbose'] or force
    puts "INVOICER: #{message}" if @settings['verbose'] or force
  end


  def fail_at(*criteria)
    @data[:valid] = false
    criteria.each  {|c|
      @errors.push c unless @errors.include? c
    }
    return nil
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
    else
      error "Template File not found!"
    end
    return false
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

  def replace_keys line
    @data.keys.each{ |key|
      replacement = (@data[key].to_s).gsub "\n"," \\newline "
      line = line.gsub('$' + key.to_s + '$', replacement)
    }
    return line
  end

  ##
  # fills the template with mined data
  def create_tex choice, check = false, run = true
    return fail_at :create_tex unless parse :products
    return fail_at :templates unless load_templates()

    unless @valid_for[choice] or check
      error "Cannot create an \"#{choice.to_s}\" from #{@data[:name]}. (#{@errors.join ','})"
    end

    template = @template_invoice if choice == :invoice
    template = @template_offer   if choice == :offer

    table = TableBox.new
    table.title = "Template matches"
    if check
      template.each_line { |line| 
        scans = line.scan /\$([^$]*)\$/
        if scans.length > 0
          findings = scans.map{|s| not @data[s[0].to_sym].nil? and not @data[s[0].to_sym] == false  }
          table.add_row [scans.flatten.join(", "), findings.join(','),]
        end
      }
      puts table
      return
    end

    file_content = []
    template.each_line { |line| 
      line = replace_keys line
      line = replace_keys line
      file_content.push line
    }

    filename = export_filename choice, "tex"
    output_path = File.join @project_folder , filename
 
    #puts file_content
    write_array_to_file file_content, output_path

    logs "Rendering #{output_path} with #{@settings['latex']}"
    silencer = @settings['verbose'] ? "" : "> /dev/null" 

    #TODO output directory is not generic
    if run
      system "#{@settings['latex']} \"#{output_path}\" -output-directory . #{silencer}"
    end


    unless @settings['keep_log']
      log = filename.gsub('.tex','.log')
      aux = filename.gsub('.tex','.aux')
      FileUtils.rm log if File.exists? log
      FileUtils.rm aux if File.exists? aux
    end

    puts "Created #{output_path} and .pdf"
  end

  def write_array_to_file file_content, path
    begin
    file = File.new path, "w"
    file_content.each do |line|
      file.write line
    end
    file.close
    logs "file written: #{path}"
    rescue
      error "Unable to write into #{path}"
    end
  end
end

class InvoiceProduct
  attr_reader :name, :hash, :tax, :valid, :returned,
    :cost_invoice, :cost_offer, :tax_invoice, :tax_offer, :price

  def initialize(name, hash, tax_value)
    @name = name
    @hash = hash
    @tax_value = tax_value

    @valid = true
    validate() unless hash.nil?
  end

  def validate()
    return false if @hash.nil?
    @valid    = false unless @hash['sold'].nil? or @hash['returned'].nil?
    @valid    = false unless @hash['amount'] and @hash['price']
    @sold     = @hash['sold']
    @price    = @hash['price'].to_euro
    @amount   = @hash['amount']
    @returned = @hash['returned']

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

  def calculate()
    @cost_invoice = (@price * @sold).to_euro
    @cost_offer   = (@price * @amount).to_euro

    @tax_invoice  = (@cost_invoice * @tax_value)
    @tax_offer    = (@cost_offer   * @tax_value)
  end
end
