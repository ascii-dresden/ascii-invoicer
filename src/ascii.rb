#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'csv'
require 'git'
require 'yaml'
require 'thor'
require 'paint'

begin
  $SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]
rescue
  $SCRIPT_PATH = File.split(File.expand_path(__FILE__))[0]
end
require "#{$SCRIPT_PATH}/lib/tweaks.rb"
require "#{$SCRIPT_PATH}/lib/Euro.rb"
require "#{$SCRIPT_PATH}/lib/InvoiceProject.rb"
require "#{$SCRIPT_PATH}/lib/ProjectPlumber.rb"
require "#{$SCRIPT_PATH}/lib/module_ascii_invoicer.rb"
require "#{$SCRIPT_PATH}/lib/textboxes.rb"

## all about settings

#where are settings located?
$SETTINGS_PATHS = {
   :global   => File.join(Dir.home, ".ascii-invoicer.yml"),
   :local    => ".settings.yml",
   :template => File.join($SCRIPT_PATH, "settings_template.yml")
}

# load default settings
$SETTINGS = YAML::load(File.open("#{$SCRIPT_PATH}/default-settings.yml"))
# load local settings ( first realy local, than look at homedir)
$SETTINGS_PATHS.values.each{ |path|
  if File.exists? path and path != $SETTINGS_PATHS[:template]
    $personal_settings                  = YAML::load(File.open(path))
    $SETTINGS['personal_settings_path'] = path
  end
}

$SETTINGS['script_path'] = $SCRIPT_PATH

# loading $SETTINGS and personal_settings
def overwrite_settings(default, custom)
  default.each do |k,v|
    if custom[k].class == Hash
      overwrite_settings default[k], custom[k]
    else
      default[k] = custom[k] unless custom[k].nil?
    end
  end
end

# mixing local and default settings
overwrite_settings $SETTINGS, $personal_settings if $personal_settings

$SETTINGS['path']        = File.expand_path $SETTINGS['path']

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
  #map "-e" => :edit #depricated
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

    puts "creating a new project name #{name}" if puts plumber.new_project name
    edit_files plumber.get_project_file_path name unless options[:dont_edit]
  end



  desc "edit index", "Edit project file."
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
    method_option :all, :type=>:boolean,
      :lazy_default=> true, :required => false, :desc => "lists all projects, ever (indezies wont work)"
    method_option :paths, :type=>:boolean, :aliases => '-p',
      :lazy_default=> true, :required => false, :desc => "list paths to .yml files"
    method_option :simple, :type=>:boolean, :aliases => '-s',
      :lazy_default=> true, :required => false, :desc => "ignore global verbose setting"
    method_option :csv, :type=>:boolean, 
      :lazy_default=> true, :required => false, :desc => "output as csv"
    method_option :yaml, :type=>:boolean,
      :lazy_default=> true, :required => false, :desc => "output as yaml"
    method_option :color, :type=>:boolean, :aliases => '-c',
      :lazy_default=> true, :required => false, :desc => "overrides the colors setting"
    method_option :no_color, :type=>:boolean, :aliases => '-n',
      :lazy_default=> true, :required => false, :desc => "overrides the colors setting"
  def list
    plumber = ProjectsPlumber.new $SETTINGS

    if options[:all]
      paths = plumber.list_projects_all
    else
      unless options[:archives]
        paths = plumber.list_projects
      else
        paths = plumber.list_projects :archive, options[:archives]
      end
    end

    $SETTINGS['colors'] = true  if options[:color]
    $SETTINGS['colors'] = false if options[:no_color]

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
      projects = open_projects paths, :invoice, :date
      print_project_list_verbose projects
    else
      projects = open_projects paths, :list, :date
      print_project_list_simple projects
    end
  end

  desc "calendar", "creates a calendar from all caterings"
  def calendar
    require 'icalendar'
    plumber = ProjectsPlumber.new $SETTINGS
    paths = plumber.list_projects :archive, 2013
    paths += plumber.list_projects :archive, 2014
    paths += plumber.list_projects

    projects = open_projects paths, :full, :date
    print_project_list_ical projects

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

  method_option :yaml, :type=>:boolean,
    :lazy_default=> true, :required => false,
    :desc => "output as yaml"

  method_option :format, :type=>:string,
    :default=> "full", :required => false,
    :desc => "used by --yaml"

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
        puts display_products project, :offer
      elsif options[:invoice]
        project.validate :invoice
        puts display_products project, :invoice
      elsif options[:yaml]

        format_default = :full
        format_options = options[:format].to_sym

        if project.requirements.keys.include? format_options
          project.validate format_options
        else
          project.validate format_default
        end

        puts project.data.to_yaml
      elsif options[:costs]
        project.validate :export
        puts display_costs project
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
    $SETTINGS['verbose'] = true if options[:verbose]
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
  method_option :print,
    :type=>:numeric,
    :lazy_default=> true,
    :required => false,
    :desc => "print"
  def invoice( *hash )
    $SETTINGS['verbose'] = true if options[:verbose]

    if options[:file]
      path = options[:file]
      name = File.basename path, ".yml"
      project = InvoiceProject.new $SETTINGS, path, name
      project.create_tex choice, options[:check], false
    else
      paths = pick_paths hash, options[:archive]
      if options[:print]
        paths.each { |path|
          project = InvoiceProject.new $SETTINGS, path
          project.validate :full
          puts project.name, project.valid_for, project.errors
        }
      else
        paths.each { |path|
          project = InvoiceProject.new $SETTINGS, path
          render_project project, :invoice
        }
      end
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

  method_option :local,
    :type=>:boolean, :aliases => "-l",
    :lazy_default=> false,
    :required => false,
    :desc => "deal with local settings"

  method_option :global,
    :type=>:boolean, :aliases => "-g",
    :lazy_default=> false,
    :required => false,
    :desc => "deal with global settings"

  def settings
    #puts $SETTINGS.to_yaml

    if options[:edit]

      if    options[:local]
        error "you are in #{Dir.home}, use --global instead" if Dir.home == FileUtils.pwd
        path = $SETTINGS_PATHS[:local]
        choice = :local

      elsif options[:global]
        path = $SETTINGS_PATHS[:global]
        choice = :global



      else
        error "please choose between --local and --global"
      end

      if not File.exists? path and no? "There is no #{path} yet do you want to use a template? (YES/no)"
        error "templatefile #{$SETTINGS_PATHS[:template]} not found" unless File.exists? $SETTINGS_PATHS[:template]
        puts "ok, I copy over a template"
        FileUtils.cp($SETTINGS_PATHS[:template], path)
      end

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
    puts "ascii-invoicer 2.3.0 alpha"
  end


end

Commander.start
