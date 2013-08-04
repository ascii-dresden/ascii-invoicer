#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'csv'
require 'yaml'
require 'thor'
require 'paint'

$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]
require "#{$SCRIPT_PATH}/lib/tweaks.rb"
require "#{$SCRIPT_PATH}/lib/InvoiceProject.rb"
require "#{$SCRIPT_PATH}/lib/ProjectPlumber.rb"
require "#{$SCRIPT_PATH}/lib/module_ascii_invoicer.rb"
require "#{$SCRIPT_PATH}/lib/textboxes.rb"
require "#{$SCRIPT_PATH}/lib/clitables.rb"

$SETTINGS                = YAML::load(File.open("#{$SCRIPT_PATH}/default-settings.yml"))
$local_settings          = YAML::load(File.open("settings.yml")) if File.exists? "settings.yml"
$SETTINGS['path']        = File.expand_path File.split(__FILE__)[0]
$SETTINGS['script_path'] = $SCRIPT_PATH

# loading $SETTINGS and local_settings
def overwrite_settings(default, custom)
  default.each do |k,v|
    if custom[k].class == Hash
      overwrite_settings default[k], custom[k]
    else
      default[k] = custom[k] unless custom[k].nil?
    end
  end
end

overwrite_settings $SETTINGS, $local_settings if $local_settings

error "settings:editor is an elaborate string: \"#{$SETTINGS['editor']}\"!\nDANGEROUS!" if $SETTINGS['editor'].include? " "
error "settings:latex is an elaborate string: \"#{$SETTINGS['editor']}\"!\nDANGEROUS!" if $SETTINGS['latex'].include? " "


# bootstraping
plumber = ProjectsPlumber.new $SETTINGS
plumber.create_dir :storage unless plumber.check_dir :storage
plumber.create_dir :working unless plumber.check_dir :working
plumber.create_dir :archive unless plumber.check_dir :archive
error "template not found!\n#{plumber.dirs[:template]}"   unless plumber.check_dir :template





# here coms thor
class Commander < Thor
  include Thor::Actions
  include AsciiInvoicer

  package_name "ascii project"
  #argument :first, :type => :numeric
  map "-l" => :list
  #map "-a" => :list ARCHIVES #XXX
  map "-d" => :display
  map "-i" => :invoice
  map "-o" => :offer

  class_option :file,      :aliases=> "-f", :type => :string
  class_option :verbose,   :aliases=> "-v", :type => :boolean
  class_option :editor,                     :type => :string
  class_option :check,                      :type => :boolean
  #class_option "keep-log", :aliases=> "-k", :type => :boolean

  desc "new NAME", "creating a new project" 
  method_option :dont_edit,
    :type=>:boolean, :aliases => "-d",
    :lazy_default=> true,
    :required => false,
    :desc => "do not edit a new file after creation"
  def new(name)
    plumber = ProjectsPlumber.new $SETTINGS

    if plumber.new_project name
      puts "creating a new project name #{name}"
      edit_file plumber.get_project_file_path name
    else
      #puts "Project #{name} already exists"
      edit_file plumber.get_project_file_path name unless options[:dont_edit]
    end
  end


  desc "edit index", "Edit project file."
  method_option :archives,
    :type=>:numeric, :aliases => "-a",
    :lazy_default=> Date.today.year,
    :required => false,
    :desc => "list archived projects"
  def edit(index=nil)
    # TODO implement edit --archive
    plumber = ProjectsPlumber.new $SETTINGS
    if options[:file]
      path = options[:file]
    else
      path = pick_project index
    end
    if path
      edit_file path, options[:editor] if options[:editor]
      edit_file path
    end
  end

  desc "list", "List current Projects."
    method_option :archives,
      :type=>:numeric, :aliases => "-a",
      :lazy_default=> Date.today.year,
      :required => false,
      :desc => "list archived projects"
    method_option :csv, :type=>:boolean,
      :lazy_default=> true, :required => false,
      :desc => "output as csv"
    method_option :yaml, :type=>:boolean,
      :lazy_default=> true, :required => false,
      :desc => "output as yaml"

  def list
    plumber = ProjectsPlumber.new $SETTINGS

    unless options[:archives]
      paths = plumber.list_projects
    else
      paths = plumber.list_projects :archive, options[:archives]
    end

    if options[:csv] 
      projects = open_projects paths, :invoice, :date
      print_project_list_csv projects
    elsif options[:yaml] 
      projects = open_projects paths, :export , :date
      print_project_list_yaml projects
    elsif options[:verbose] 
      projects = open_projects paths, :export , :date
      print_project_list_verbose projects
    else
      projects = open_projects paths, :list, :date
      print_project_list_plain projects
    end
  end



  desc "display NAME", "Shows information about a Project in different ways."
  def display(index=nil)
    if options[:file]
      path = options[:file]
    else
      path = pick_project index
    end
    project = InvoiceProject.new $SETTINGS, path
    #data = project.data
    if options[:verbose]
      project.validate :full, true
      #pp project.data#.keep_if{|k,v| k != :products}
      puts project.valid_for
      puts project.errors
    else
      project.validate :invoice
      costbox project
    end
  end

  desc "archive NAME", "Move project to archive."
  def archive(name)
    # TODO implement archive Project
    plumber = ProjectsPlumber.new $SETTINGS
    path = pick_project(name)

    project = InvoiceProject.new $SETTINGS, path
    project.validate(:invoice)

    data   = project.data
    year   = data[:date].year
    prefix = data[:invoice_number].to_s + "_"
    name   = data[:name]

    unless data[:valid]
      error "\"#{name}\" contains errors\n(#{project.errors.join(',')})"
    end

    if yes? "Do you want to move \"#{prefix}#{name}\" into the archives of #{year}? (yes|No)"
      new_path = plumber.archive_project name, year, prefix
      puts new_path

    else puts "ok, so not"
    end
  end


  desc "reopen YEAR NAME", "Reopen an archived project."
  def reopen(year, name)
    # TODO finish reopen
    plumber = ProjectsPlumber.new $SETTINGS
    project = InvoiceProject.new $SETTINGS, pick_project(name,year)
    name = project.data[:name]
    unless plumber.unarchive_project name, year
      error "Can't unarchive #{name}, checks names of current projects for duplicates!"
    end
  end


  desc "offer NAME", "Create an offer from project file."
  def offer(index=nil)
    # TODO implement offer --archive
    if options[:file]
      path = options[:file]
    else
      path = pick_project index
    end
    project = InvoiceProject.new $SETTINGS, path

    project.validate :offer
    if project.valid_for[:offer]
      project.create_tex :offer, options[:check]
    else
      error "#{project.name} is not ready for creating an offer!"
    end
  end


  desc "invoice NAME", "Create an invoice from project file."
  def invoice(index=nil)
    # TODO implement invoice --archive
    if options[:file]
      path = options[:file]
    else
      path = pick_project index
    end
    project = InvoiceProject.new $SETTINGS, path
 
    project.validate :invoice
    if project.valid_for[:invoice]
      project.create_tex :invoice, options[:check]
    else
      error "#{project.name} is not ready for creating an invoice!"
    end
  end

  desc "settings", "view Settings"
  def settings
    #puts $SETTINGS.to_yaml
    pp $SETTINGS
  end
end

Commander.start
