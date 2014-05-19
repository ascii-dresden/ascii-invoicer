#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'csv'
require 'git'
require 'yaml'
require 'thor'
require 'paint'

$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]
require "#{$SCRIPT_PATH}/lib/tweaks.rb"
require "#{$SCRIPT_PATH}/lib/Euro.rb"
require "#{$SCRIPT_PATH}/lib/InvoiceProject.rb"
require "#{$SCRIPT_PATH}/lib/ProjectPlumber.rb"
require "#{$SCRIPT_PATH}/lib/module_ascii_invoicer.rb"
require "#{$SCRIPT_PATH}/lib/textboxes.rb"

local_settings_paths = [
  File.join(Dir.home, ".ascii-invoicer.yml"),
  ".settings.yml"
]

$SETTINGS                = YAML::load(File.open("#{$SCRIPT_PATH}/default-settings.yml"))
local_settings_paths.each{ |path|
  if File.exists? path
    $local_settings          = YAML::load(File.open(path))
    $SETTINGS['local_settings_path'] = path
  end
}
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

#error "settings:editor is an elaborate string: \"#{$SETTINGS['editor']}\"!\nDANGEROUS!" if $SETTINGS['editor'].include? " "
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
  map "-d" => :display
  map "-i" => :invoice
  map "-o" => :offer
  map "-e" => :edit
  #map "--version" => :version

  class_option :file,      :aliases=> "-f", :type => :string
  class_option :verbose,   :aliases=> "-v", :type => :boolean
  class_option :editor,                     :type => :string
  #class_option "keep-log", :aliases=> "-k", :type => :boolean





  desc "new NAME", "creating a new project" 
  method_option :dont_edit,
    :type=>:boolean, :aliases => "-d",
    :lazy_default=> true,
    :required => false,
    :desc => "do not edit a new file after creation"
  def new(name)
    plumber = ProjectsPlumber.new $SETTINGS
    name = name.deumlautify

    if plumber.new_project name
      puts "creating a new project name #{name}"
      edit_files plumber.get_project_file_path name
    else
      #puts "Project #{name} already exists"
      edit_files plumber.get_project_file_path name unless options[:dont_edit]
    end
  end



  desc "edit indexs", "Edit project file."
  method_option :archive,
    :type=>:numeric, :aliases => "-a",
    :default => nil,
    :lazy_default=> Date.today.year,
    :required => false,
    :desc => "Open File from archive YEAR"
  def edit( *hash )
    # TODO implement edit --archive
    plumber = ProjectsPlumber.new $SETTINGS
    paths = pick_paths hash, options[:archive]

    if paths.size > 0
      edit_files paths, options[:editor]
    else
      puts "nothing found (#{hash})"
    end
  end



  desc "list", "List current Projects."
    method_option :archives,
      :type=>:numeric, :aliases => "-a",
      :lazy_default=> Date.today.year, :required => false, :desc => "list archived projects"
    method_option :paths, :type=>:boolean, :aliases => '-p',
      :lazy_default=> true, :required => false, :desc => "list paths to .yml files"
    method_option :simple, :type=>:boolean, :aliases => '-s',
      :lazy_default=> true, :required => false, :desc => "ignore global verbose setting"
    method_option :csv, :type=>:boolean, :aliases => '-c',
      :lazy_default=> true, :required => false, :desc => "output as csv"
    method_option :yaml, :type=>:boolean,
      :lazy_default=> true, :required => false, :desc => "output as yaml"
  def list
    plumber = ProjectsPlumber.new $SETTINGS

    unless options[:archives]
      paths = plumber.list_projects
    else
      paths = plumber.list_projects :archive, options[:archives]
    end

    if options[:csv] 
      projects = open_projects paths, :export, :date
      print_project_list_csv projects
    elsif options[:paths] 
      projects = open_projects paths, :export , :date
      print_project_list_paths projects
    elsif options[:yaml] 
      projects = open_projects paths, :export , :date
      print_project_list_yaml projects
    elsif options[:simple]
      projects = open_projects paths, :list, :date
      print_project_list_simple projects
    elsif options[:verbose] or $SETTINGS['verbose']
      projects = open_projects paths, :export , :date
      print_project_list_verbose projects
    else
      projects = open_projects paths, :list, :date
      print_project_list_simple projects
    end
  end



  desc "display NAME", "Shows information about a Project in different ways."
  method_option :archive,
    :type=>:numeric, :aliases => "-a",
    :default => nil,
    :lazy_default=> Date.today.year,
    :required => false,
    :desc => "Open File from archive YEAR"
  method_option :offer, :type=>:boolean,
    :default=> false, :lazy_default=> true, :required => false,
    :desc => "Display Products parsed as OFFER"
  method_option :invoice, :type=>:boolean,
    :default=> false, :lazy_default=> true, :required => false,
    :desc => "Display Products parsed as INVOICE"
  method_option :costs,:type=>:boolean,
    :default=> true, :lazy_default=> true, :required => false,
    :desc => ""
  #method_option :yaml, :type=>:boolean,
  #  :lazy_default=> true, :required => false,
  #  :desc => "output as yaml"
  def display(index=nil)
    if options[:file]
      path = options[:file]
      name = File.basename path, ".yml"
      project = InvoiceProject.new $SETTINGS, path, name
    else
      path = pick_project index, options[:archive]
      project = InvoiceProject.new $SETTINGS, path
    end
    #data = project.data
    if options[:verbose]
      project.validate :full, true
      #pp project.data#.keep_if{|k,v| k != :products}
      puts project.valid_for
      puts project.errors
    else
      if options[:offer]
        project.validate :offer
        display_products project, :offer
      elsif options[:invoice]
        project.validate :invoice
        display_products project, :invoice
      elsif options[:yaml]
        project.validate :export
        puts project.to_yaml
      elsif options[:costs]
        project.validate :export
        display_costs project
      end
    end
  end



  desc "archive NAME", "Move project to archive."
  method_option :force,:type=>:boolean,
    :lazy_default=> true, :required => false,
    :desc => "Force archiving projects that are invalid."
  def archive(name)
    # TODO implement archive Project
    plumber = ProjectsPlumber.new $SETTINGS
    path = pick_project(name)

    project = InvoiceProject.new $SETTINGS, path
    project.validate(:invoice)

    data   = project.data
    year   = data[:date].year
    prefix = data[:invoice_number].nil? ? "" : data[:invoice_number]
    name   = data[:name]

    unless data[:valid] or options[:force]
      error "\"#{name}\" contains errors\n(#{project.errors.join(',')})"
    end

    if yes? "Do you want to move \"#{prefix}_#{name}\" into the archives of #{year}? (yes|No)"
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
  method_option :archive,
    :type=>:numeric, :aliases => "-a",
    :default => nil,
    :lazy_default=> Date.today.year,
    :required => false,
    :desc => "Open File from archive YEAR"
  method_option :check,
    :type=>:numeric, :aliases => "-d",
    :lazy_default=> true,
    :required => false,
    :desc => "check"
  def offer( *hash )
    # TODO implement offer --archive
    if options[:file]
      path = options[:file]
      name = File.basename path, ".yml"
      project = InvoiceProject.new $SETTINGS, path, name
      render_project project, :offer
    else
      paths = pick_paths hash, options[:archive]
      paths.each { |path|
        project = InvoiceProject.new $SETTINGS, path
        render_project project, :offer
      }
    end
  end



  desc "invoice NAME", "Create an invoice from project file."
  method_option :archive,
    :type=>:numeric, :aliases => "-a",
    :default => nil,
    :lazy_default=> Date.today.year,
    :required => false,
    :desc => "Open File from archive YEAR"
  method_option :check,
    :type=>:numeric, :aliases => "-d",
    :lazy_default=> true,
    :required => false,
    :desc => "check"
  def invoice( *hash )
    # TODO implement invoice --archive
    if options[:file]
      path = options[:file]
      name = File.basename path, ".yml"
      project = InvoiceProject.new $SETTINGS, path, name
      render_project project, :invoice
    else
      paths = pick_paths hash, options[:archive]
      paths.each { |path|
        project = InvoiceProject.new $SETTINGS, path
        render_project project, :invoice
      }
    end
  end



  desc "status", "Git Integration."
  def status
    plumber = ProjectsPlumber.new $SETTINGS
    if plumber.check_git()
      plumber.git_status()
    else
      puts "problems with git"
    end
  end


  desc "add NAME", "Git Integration."
  def add index
    plumber = ProjectsPlumber.new $SETTINGS
    if options[:file]
      path = options[:file]
    else
      project = InvoiceProject.new $SETTINGS, pick_project(index)
      path = project.project_folder
    end
    if plumber.check_git()
      plumber.git_update_path(path)
    else
      puts "problems with git"
    end
  end


  desc "commit message", "Git Integration."
  def commit message
    plumber = ProjectsPlumber.new $SETTINGS
    if plumber.check_git()
      plumber.git_commit(message)
    else
      puts "problems with git"
    end
  end


  desc "push", "Git Integration."
  def push
    plumber = ProjectsPlumber.new $SETTINGS
    if plumber.check_git()
      plumber.git_push()
    end
  end

  desc "pull", "Git Integration."
  def pull
    plumber = ProjectsPlumber.new $SETTINGS
    if plumber.check_git()
      plumber.git_pull()
    end
  end


  desc "history", "Git Integration."
  method_option :count,
    :type=>:numeric, :aliases => "-c",
    :default => 30,
    :lazy_default=> 1000, 
    :required => false,
    :desc => "Max count of history entries"
  def history
    plumber = ProjectsPlumber.new $SETTINGS
    if plumber.check_git()
      plumber.git_log(options[:count])
    else
      puts "problems with git"
    end
  end



  desc "settings", "view Settings"
  method_option :edit,
    :type=>:boolean, :aliases => "-e",
    :lazy_default=> false,
    :required => false,
    :desc => "edit your local settings"
  def settings
    #puts $SETTINGS.to_yaml
    if options[:edit]
      path = File.join($SETTINGS['path'], ".settings.yml")
      edit_files path
    else
      puts $SETTINGS.to_yaml
      #pp $SETTINGS
    end
  end



  desc "version", "display Version"
  def version
    #git = Git.open $SCRIPT_PATH+'/..'
    #current = git.log.to_s.lines.to_a.last
    ##puts git.branch unless git.tags.include? current 
    #puts current
    puts "ascii-invoicer 2.2.4"
  end


end

Commander.start
