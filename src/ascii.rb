#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'thor'
require 'paint'
require 'yaml'
require 'csv'

$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]
require "#{$SCRIPT_PATH}/lib/InvoiceProject.rb"
require "#{$SCRIPT_PATH}/lib/minizen.rb"
require "#{$SCRIPT_PATH}/lib/ProjectPlumber.rb"
require "#{$SCRIPT_PATH}/lib/ascii_invoicer.rb"

$SETTINGS = YAML::load(File.open("#{$SCRIPT_PATH}/default-settings.yml"))
$local_settings = YAML::load(File.open("settings.yml")) if File.exists? "settings.yml"

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


# bootstraping
@plumber = ProjectsPlumber.new $SETTINGS
@plumber.create_dir :storage unless @plumber.check_dir :storage
@plumber.create_dir :working unless @plumber.check_dir :working
@plumber.create_dir :archive unless @plumber.check_dir :archive
error "template not found!\n#{@plumber.dirs[:template]}"   unless @plumber.check_dir :template





# here coms thor
class Commander < Thor
  include Thor::Actions
  include AsciiInvoiceProject

  package_name "ascii project"
  #argument :first, :type => :numeric
  map "-l" => :list

  class_option :file,      :aliases=> "-f", :type => :boolean
  class_option :verbose,   :aliases=> "-v", :type => :boolean
  #class_option "keep-log", :aliases=> "-k", :type => :boolean


  #desc "new NAME", "creating a new project" 
  #def new(name)
  #  @plumber = ProjectsPlumber.new $SETTINGS
  #  if @plumber.new_project name
  #    puts "creating a new project name #{name}"
  #    edit_file @plumber.get_project_file_path name
  #  else
  #    #puts "Project #{name} already exists"
  #    edit_file @plumber.get_project_file_path name
  #  end
  #end


  desc "settings", "view Settings"
  def settings
    puts $SETTINGS.to_yaml
  end


  #desc "edit index", "Edit project file."
  #method_option :archives,
  #  :type=>:numeric, :aliases => "-a",
  #  :lazy_default=> Date.today.year,
  #  :required => false,
  #  :desc => "list archived projects"
  #def edit(index)
  #  # TODO implement edit --archive
  #  path = pick_project index
  #  edit_file path if path
  #end

  #def method_missing(arguments)
  #  edit arguments.to_s if arguments
  #end


  desc "list", "List current Projects."
    method_option :archives,
      :type=>:numeric, :aliases => "-a",
      :lazy_default=> Date.today.year,
      :required => false,
      :desc => "list archived projects"
    #method_option :csv, :type=>:boolean,
    #  :lazy_default=> true, :required => false,
    #  :desc => "output as csv"
    #method_option :yaml, :type=>:boolean,
    #  :lazy_default=> true, :required => false,
    #  :desc => "output as yaml"
  def list
    @plumber = ProjectsPlumber.new $SETTINGS
    unless options[:archives]
      paths = @plumber.list_projects
    else
      paths = @plumber.list_projects :archive, options[:archives]
    end
    print_project_list paths, options
  end




  #desc "archive NAME", "Move project to archive."
  #def archive(index)
  #  # TODO implement archive Project
  #  path = pick_project index
  #  plumber = ProjectsPlumber.new $SETTINGS
  #  project = InvoiceProject.new $SETTINGS
  #  project.load_project path
  #  project.validate
  #  data = project.data
  #  year = data['date'].year
  #  prefix= data['numbers']['invoice_short'].to_s + "_"
  #  name = data['name']


  #  error "\"#{name}\" contains errors\n(#{data['parse_errors'].join(',')})" ;exit unless data['valid']
  #  error "\"#{name}\" has no invoice number"; exit

  #  puts "Selected: #{ path}"

  #  if yes? "Do you want to move \"#{prefix}#{name}\" into the archives of #{year}? (yes|No)"
  #    new_path = plumber.archive_project name, year, rnum
  #    puts new_path

  #  else
  #    puts "ok, so not"
  #  end
  #end




  #desc "reopen NAME", "Reopen an archived project."
  #def reopen(name)
  #end




  #desc "help", "overwriting default help."
  #def help()
  #  puts "here is my default command"
  #end




  #desc "show NAME", "Show information about the project."
  #def show(name)
  #  @plumber = ProjectsPlumber.new $SETTINGS

  #  project = @plumber.pick_project name
  #  file    = @plumber.get_project_file project
  #  data    = @plumber.open_project file
  #  puts "\"#{data['event']}\":".ljust(30) + "#{data['summe'].rjust 8}"
  #  puts "MORE TO COME"
  #end




  #desc "offer NAME", "Create an offer from project file."
  #def offer(name)
  #  # TODO implement offer --archive
  #  @plumber = ProjectsPlumber.new $SETTINGS
  #  puts @plumber.pick_project name
  #end




  #desc "invoice NAME", "Create an invoice from project file."
  #def invoice(name)
  #  # TODO implement invoice --archive
  #  @plumber = ProjectsPlumber.new $SETTINGS
  #  puts @plumber.pick_project name
  #end




  #desc "reopen NAME", "Opposite of \"archive\"."
  #def reopen(name)
  #  puts @plumber.pick_project name
  #  puts "NOT YET IMPLEMENTED"
  #end

end

Commander.start
