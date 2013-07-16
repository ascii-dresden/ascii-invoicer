# encoding: utf-8
require 'pp'

class Invoicer

  attr_reader :project_file


  def initialize(settings)
    # expecting to find in settings
    #   @settings.template_files= {}
    #   @settings.template_files[:invoice]
    #   @settings.template_files[:offer]
    #
    
    @settings = settings

    check_offer_template   = File.exists? @settings.template_files[:offer]
    check_invoice_template = File.exists? @settings.template_files[:invoice]

    loaded_templates = load_templates()
    return loaded_templates
  end

  ## open given .yml and parse into @data
  def load_project(path)
    @project_file = path

    if File.exists?(path)

      begin
        @project_data = YAML::load(File.open(path))
      rescue
        logs "error reading #{path}"
      end
      
      pp @project_data

    end
  end


  def load_templates()
    offer   = @settings.template_files[:offer]
    invoice = @settings.template_files[:invoice]
    @template_offer   = File.open(offer).read   if File.exists?(offer)
    @template_invoice = File.open(invoice).read if File.exists?(invoice)

    return offer and invoice
  end

  def match_addressing(keyword, lang)
  end

  def mine
  end

  def mine_meta_data
  end

  def mine_products
  end

  def tex_product_table
  end

  def is_valid
  end

  def filename
  end

  def create
  end

  def dump
  end

  ##
  # *wrapper* for puts()
  # depends on @settings.silent = true|false

  def logs message, force = false
    puts "       #{__FILE__} : #{message}" unless @settings.silent and not force
  end


end
