# encoding: utf-8
require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'
require File.join File.dirname(__FILE__) + '/ProjectParserBase.rb'
require File.join File.dirname(__FILE__) + '/ProjectParser_pre250.rb'
require File.join File.dirname(__FILE__) + '/ProjectParser.rb'
require File.join File.dirname(__FILE__) + '/Euro.rb'
require 'yaml'

class InvoiceProject
  attr_reader :project_path, :project_folder, :data, :raw_data, :STATUS, :errors, :valid_for, :requirements
  attr_writer :raw_data, :errors


  def initialize(settings, project_path = nil, name = nil)
    @settings = settings
    @STATUS   = :ok # :ok, :canceled, :unparsable
    @errors   = []
    @data     = {}

    open(project_path, name) unless project_path.nil?

    #fail_at :template_offer   unless File.exists? @settings['templates']['offer']
    #fail_at :template_invoice unless File.exists? @settings['templates']['invoice']

    @settings['requirements'] = {
      :list    => [ :canceled, :tax, :date, :date_end, :manager, :name, :offer_number, :invoice_number ],

      :offer   => [ :canceled,
                    :tax, :date, :date_end, :raw_date, :manager, :name,
                    :hours, :salary, :salary_total, :costs,
                    :costs_offer, :taxes_offer, :total_offer, :final_offer,
                    :offer_number,
                    :address, :messages,
                    :event, :signature, :addressing,
                    :tex_table_offer,
                    :script_path
                  ],
      :invoice => [ :canceled,
                    :tax, :date, :date_end, :raw_date, :manager, :name,
                    :hours, :salary, :salary_total, :costs,
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
                    :hours, :salary, :salary_total,
                    :costs_offer,    :taxes_offer,    :total_offer,    :final_offer,
                    :costs_invoice,  :taxes_invoice,  :total_invoice,  :final_invoice,
                    :invoice_number, :invoice_number_long,
                    :address, :event, :offer_number, :costs,
                    :signature, :addressing,
                    :tex_table_offer, :tex_table_invoice,
                    :caterers, :messages, :request_message,:description,
                    :script_path
                  ],
      :export  => [ :canceled,
                    :tax, :date, :date_end,
                    :manager, :name, :hours,
                    :time, :time_end,
                    :hours, :salary, :salary_total,
                    :costs_offer,    :taxes_offer,    :total_offer,    :final_offer,
                    :costs_invoice,  :taxes_invoice,  :total_invoice,  :final_invoice,
                    :invoice_number, :invoice_number_long,
                    :address, :event, :offer_number, :costs,
                    :invoice_number, :invoice_number_long,
                    :caterers, :request_message, :description
      ],
    }
  end

  ## open given .yml and parse into @data
  def open(project_path, name = nil)
    #puts "opening \"#{project_path}\""
    raise "already opened another project" unless @project_path.nil?
    @project_path = project_path
    @project_folder = File.split(project_path)[0]

    if File.exists?(project_path)
      if name.nil?
        @data[:name]  = File.basename File.split(@project_path)[0]
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
        init_parser()

        @data[:valid] = true # at least for the moment
        @data[:project_path]  = project_path

        @data[:lang]  = @raw_data['lang']? @raw_data['lang'] : @settings['default_lang']
        @data[:lang]  = @data[:lang].to_sym

        return @raw_data
      end

    else
      fail_at :project_path
      error "FILE \"#{project_path}\" does not exist!"
    end
    return false
  end

  def init_parser
    @PARSER = InvoiceParser_pre250.new @settings, @raw_data, self
  end

  def name
    @data[:canceled] ? "CANCELED: #{@data[:name]}" : @data[:name]
  end

  def valid_for
    @PARSER.valid_for
  end

  def validate(type, print = false)
    @PARSER.validate(type, print)
  end

  def parse(key, parser = "parse_#{key}", parameter = nil)
    return @PARSER.parse key, parser, parameter
  end

  def raw_data= raw_data
    @raw_data = raw_data
    init_parser() unless @PARSER
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

  ##
  # fills the template with mined data
  def create_tex choice, check = false, run = true
    return fail_at :create_tex unless parse :products
    return fail_at :templates unless load_templates()

    unless valid_for[choice] or check
      error "Cannot create an \"#{choice.to_s}\" from #{@data[:name]}. (#{@errors.join ','})"
    end

    output_path = File.expand_path @settings['output_path']
    error "your output_path is not a directory! (#{output_path})" unless File.directory? output_path

    template = @template_invoice if choice == :invoice
    template = @template_offer   if choice == :offer

    template = ERB.new(template).result(binding)
    result   = ERB.new(template).result(binding)

    filename = export_filename choice, "tex"
    output_path = File.join @project_folder , filename
 
    puts output_path
    write_to_file result, output_path
    render_tex output_path, filename if run
  end

  def render_tex path, filename
    logs "Rendering #{path} with #{@settings['latex']}"
    silencer = @settings['verbose'] ? "" : "> /dev/null" 

    #TODO output directory is not generic
    system "#{@settings['latex']} \"#{path}\" -output-directory . #{silencer}"

    output_path = File.expand_path @settings['output_path']
    error "your output_path is not a directory! (#{output_path})" unless File.directory? output_path

    pdf = filename.gsub('.tex','.pdf')
    log = filename.gsub('.tex','.log')
    aux = filename.gsub('.tex','.aux')
    unless @settings['keep_log']
      FileUtils.rm log if File.exists? log
      FileUtils.rm aux if File.exists? aux
    else
      unless File.expand_path output_path == FileUtils.pwd
        FileUtils.mv log, output_path if File.exists? log
        FileUtils.mv aux, output_path if File.exists? aux
      end
    end
    FileUtils.mv pdf, output_path if File.exists? pdf


    puts "Created #{path}"
  end

  def write_to_file file_content, path
    begin
    file = File.new path, ?w
    file_content.lines.each do |line|
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
