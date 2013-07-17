# encoding: utf-8
require 'ostruct'

class Invoicer

  attr_reader :project_file, :project_data


  def initialize(settings)
    # expecting to find in settings
    #   @settings.template_files= {}
    #   @settings.template_files[:invoice]
    #   @settings.template_files[:offer]
    #
    
    @settings = settings

    check_offer_template   = File.exists? @settings.template_files[:offer]
    check_invoice_template = File.exists? @settings.template_files[:invoice]

    load_templates()
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
      return true
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
    #puts @raw_project_data.client
    return true
  end

  ##
  # takes raw_project_data
  # manipulates @project_data
  # returns true or false
  def parse_project_date(raw_project_data)
    #reading date
    begin
      @project_data.date    = strpdates(raw_project_data.date)[0]
      @project_data.enddate = strpdates(raw_project_data.date)[1]
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
  def parse_project_hours(raw_project_data)
    @project_data.hours = OpenStruct.new raw_project_data.hours
    sum = 0
    @project_data.hours.caterers.values.each {|v| sum+=v}
    @project_data.hours.sum = sum
    return (sum == @project_data.hours.time)
  end

  ##
  def read_meta_data()
    return false if @raw_project_data.nil?
    client = parse_project_client @raw_project_data
    date   = parse_project_date   @raw_project_data
    hours  = parse_project_hours  @raw_project_data

    return (date and hours and client)

    #address
    #client
    #addressing
    #offer_number
    #invoice_number
    

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
        puts t
        return [t]

      elsif p_range.length == 2
        t1 = Date.new p[2].to_i, p[1].to_i, p_range[0].to_i
        t2 = Date.new p[2].to_i, p[1].to_i, p_range[1].to_i
        puts t1, t2
        return [t1,t2]

      else
        fail
      end
    end
  end


end
