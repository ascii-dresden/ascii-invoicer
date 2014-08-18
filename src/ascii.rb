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

require "#{$SCRIPT_PATH}/lib/Euro.rb"
require "#{$SCRIPT_PATH}/lib/InvoiceProject.rb"
require "#{$SCRIPT_PATH}/lib/HashTransform.rb"
require "#{$SCRIPT_PATH}/lib/ProjectsPlumber.rb"
require "#{$SCRIPT_PATH}/lib/Textboxes.rb"

require "#{$SCRIPT_PATH}/lib/shell.rb"
require "#{$SCRIPT_PATH}/lib/tweaks.rb"
require "#{$SCRIPT_PATH}/lib/ascii_invoicer.rb"

include Shell
## all about settings

## where are settings located?
$SETTINGS_PATHS = {
   :global   => File.join(Dir.home, ".ascii-invoicer.yml"),
   :local    => ".settings.yml",
   :template => File.join($SCRIPT_PATH, "settings_template.yml")
}

## load default settings
begin
  $SETTINGS = YAML::load(File.open("#{$SCRIPT_PATH}/default-settings.yml"))
rescue SyntaxError => error
  warn "error parsing default-settings.yml. Do not modify those directly! Only overwrite settings in #{$SETTINGS_PATHS[:global]}"
  puts error
end
# load local settings ( first realy local, than look at homedir)
$SETTINGS_PATHS.values.each{ |path|
  if File.exists? path and path != $SETTINGS_PATHS[:template]
    begin
      $personal_settings                  = YAML::load(File.open(path))
    rescue SyntaxError => error
      warn "error parsing #{File.expand_path path}."
      puts error
    end
    $SETTINGS['personal_settings_path'] = path
  end
}

## loading $SETTINGS and grafting $personal_settings to them
$SETTINGS.graft $personal_settings if $personal_settings

## Default editor if not set ins settings files
$SETTINGS["editor"] ||= ENV['EDITOR']

## Version of the software
$SETTINGS['version'] = $VERSION = "v2.4.1"

## path to the source code
$SETTINGS['script_path'] = $SCRIPT_PATH

## path to the project File, here we expand the "~"
$SETTINGS['path']        = File.expand_path $SETTINGS['path']

## security
#error "settings:editor is an elaborate string: \"#{$SETTINGS['editor']}\"!\nDANGEROUS!" if $SETTINGS['editor'].include? " "
error "settings:latex is an elaborate string: \"#{$SETTINGS['latex']}\"!\nDANGEROUS!" if $SETTINGS['latex'].include? " "
error "settings:output_path is an elaborate string: \"#{$SETTINGS['output_path']}\"!\nDANGEROUS!" if $SETTINGS['output_path'].include? " "


## bootstraping the plumber, first run creates all folders
$PLUMBER = ProjectsPlumber.new $SETTINGS, InvoiceProject
$PLUMBER.create_dir :storage unless $PLUMBER.check_dir :storage
$PLUMBER.create_dir :working unless $PLUMBER.check_dir :working
$PLUMBER.create_dir :archive unless $PLUMBER.check_dir :archive
error "template not found!\n#{$PLUMBER.dirs[:template]}" unless $PLUMBER.check_dir :template





## here coms thor
class Commander < Thor
  include Thor::Actions
  include AsciiInvoicer

  package_name "ascii invoicer"
  #argument :first, :type => :numeric
  map "-l"   => :list
  map "l"   => :list
  map "ls"   => :list
  map "dir"  => :list
  map "show" => :display
  map "-d"   => :display
  map "-i"   => :invoice
  map "-o"   => :offer
  #map "-e"  => :edit #depricated
  #map "--version" => :version

  class_option :file,      :aliases=> "-f", :type => :string
  class_option :verbose,   :aliases=> "-v", :type => :boolean, :default => $SETTINGS['verbose']
  class_option :editor,                     :type => :string,  :default => $SETTINGS['editor']
  #class_option "keep-log", :aliases=> "-k", :type => :boolean

  no_commands{
    def open_projects(names, options)
      $SETTINGS['verbose'] = true if options[:verbose]
      if options[:file]
        return [InvoiceProject.new(options[:file], (File.basename options[:file], ".yml"))]
      else
        if options[:archive]
          $PLUMBER.open_projects(:archive, options[:archive])
        else
          $PLUMBER.open_projects()
        end

        return names.map{|name| $PLUMBER.lookup name } if names.class == Array
        return $PLUMBER.lookup names if names.class == String
        return nil
      end
    end

    def render_projects(projects, type, stdout = false)
      projects.each{|project| project.create_tex(type, stdout) unless project.nil? }
    end
  }


  desc "new NAME", "creating a new project" 
    method_option :dont_edit,
      :type=>:boolean, :aliases => "-d",
      :lazy_default=> true,
      :required => false,
      :desc => "do not edit a new file after creation"
  def new(name)
    puts "creating a new project name #{name}" if puts $PLUMBER.new_project name
    edit_files $PLUMBER.get_project_file_path name unless options[:dont_edit]
  end


  desc "edit index", "Edit project file."
    method_option :archive,
      :type=>:numeric, :aliases => "-a",
      :default => nil,
      :lazy_default=> Date.today.year,
      :required => false,
      :desc => "Open File from archive YEAR"
  def edit( *hash )
    if options[:archive]
      $PLUMBER.open_projects(:archive, options[:archive])
    else
      $PLUMBER.open_projects()
    end

    paths= hash.map { |name| $PLUMBER.lookup_path(name) }

    if paths.size > 0
      edit_files paths, options[:editor]
    else
      puts "nothing found (#{hash})"
    end
  end



  desc "list", "List current Projects."
    method_option :archive,
      :type=>:numeric, :aliases => "-a",
      :lazy_default=> Date.today.year, :required => false, :desc => "list archived projects"
    method_option :all, :type=>:boolean,
      :lazy_default=> true, :required => false, :desc => "lists all projects, ever (indezies wont work)"
    method_option :paths, :type=>:boolean, :aliases => '-p',
      :lazy_default=> true, :required => false, :desc => "list paths to .yml files"


    method_option :csv, :type=>:boolean, 
      :lazy_default=> true, :required => false, :desc => "output as csv"
    method_option :sort, :type=>:string, :default => 'date',
      :required => false, :desc => "sort by [date | index | name]",
      :enum => ['date' , 'index', 'name']

    method_option :show_caterers, :type=>:boolean,
      :lazy_default=> true, :required => false, :desc => "list caterers"

    method_option :show_blockers, :type=>:boolean, :aliases => '-b',
      :lazy_default=> true, :required => false, :desc => "list blockers"

    method_option :show_errors, :type=>:boolean, :aliases => '-e',
      :lazy_default=> true, :required => false, :desc => "list errors"

    method_option :simple, :type=>:boolean, :aliases => '-s',
      :lazy_default=> true, :required => false, :desc => "overrides the verbose setting"

    method_option :colors, :type=>:boolean, :aliases => '-c', :default => $SETTINGS['colors'],
      :lazy_default=> true, :required => false, :desc => "overrides the colors setting"

    method_option :no_colors, :type=>:boolean, :aliases => '-n',
      :lazy_default=> true, :required => false, :desc => "overrides the colors setting"


  def list
    if options[:all]
      $PLUMBER.open_projects_all()
    elsif options[:archive]
      $PLUMBER.open_projects(:archive, options[:archive])
    else
      $PLUMBER.open_projects()
    end

    hash                 = {}
    hash[:verbose]       = (options[:verbose] and !options[:simple])
    hash[:colors]        = (options[:colors] and !options[:no_colors])
    hash[:show_errors]   = options[:show_errors]
    hash[:show_blockers] = options[:show_blockers]
    hash[:show_caterers] = options[:show_caterers]

    if [:date, :name, :index].include? options[:sort].to_sym
      $PLUMBER.sort_projects options[:sort].to_sym
    else
      puts "can't sort by #{options[:sort]}"
    end

    projects = $PLUMBER.opened_projects

    if options[:csv] 
      $PLUMBER.sort_projects(:index)
      print_project_list_csv projects
    elsif options[:paths] 
      print_project_list_paths projects
    elsif options[:yaml] 
      print_project_list_yaml projects
    else
      print_project_list(projects, hash)
    end
  end

  desc "csv", "invokes list --all --csv"
  def csv
    invoke :list, [], csv:true, all:true # where is this documented
  end

  desc "calendar", "creates a calendar from all caterings"
  def calendar
    $PLUMBER.open_projects_all()

    print_project_list_ical $PLUMBER.opened_projects
  end




  desc "archive NAME", "Move project to archive."
    method_option :force,:type=>:boolean,
      :lazy_default=> true, :required => false,
      :desc => "Force archiving projects that are invalid."
  def archive(name)
    $PLUMBER.open_projects
    project = $PLUMBER.lookup name

    year   = project.date.year
    prefix = project.data[:invoice][:number]
    prefix ||= ""
    prefix  += "canceled" if project.data[:canceled]

    unless project.validate(:archive) or options[:force] or project.data[:canceled]
      error "\"#{project.name}\" contains errors\n(#{project.ERRORS.join(',')})"
    else
      new_path = $PLUMBER.archive_project project, Date.today.year, prefix
      puts new_path
    end
  end

  desc "reopen YEAR NAME", "Reopen an archived project."
  def reopen(year, name)
    $PLUMBER.open_projects :archive, year
    project = $PLUMBER.lookup name

    name = project.data[:name]
    unless $PLUMBER.unarchive_project project, year
      error "Can't unarchive #{name}, checks names of current projects for duplicates!"
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
    method_option :caterers, :type=>:boolean,
      :default=> false, :lazy_default=> true, :required => false,
      :desc => "Display Caterers"
    method_option :raw,:type=>:boolean,
      :default=> false, :lazy_default=> true, :required => false,
      :desc => ""
    method_option :costs,:type=>:boolean,
      :default=> false, :lazy_default=> true, :required => false,
      :desc => ""
    method_option :pp, :type=>:string, :banner => "key",
      :default => nil, :lazy_default=> "", :required => false,
      :desc => "output key or all with pp"
    method_option :yaml, :type=>:string, :banner => "key",
      :default => nil, :lazy_default=> "", :required => false,
      :desc => "output key or all as yaml"
    method_option :cal, :type=>:boolean,
      :default => nil, :lazy_default=> "", :required => false,
      :desc => "output key or all as ical event[s]"
  def display(*names)
    projects =  open_projects names, options
    projects.each{ |project|
      error("No project found!") if project.nil?
    
    unless options[:cal] or options[:yaml] or options[:costs] or options[:caterers] or options[:invoice] or options[:offer]
      fallback= true
    end

    if not options[:yaml].nil?
      if options[:yaml] == ''
        puts project.data.to_yaml
      else
        puts project.data.get(options[:yaml]).to_yaml
      end
    elsif options[:raw]
      raw = project.raw_data
      raw.delete "cataloge"
      puts raw.to_yaml
    elsif not options[:pp].nil?
      if options[:pp] == ''
        pp project.data
      else
        pp project.data.get(options[:pp])
      end
    else
      puts display_products(project, :offer  ) if options[:offer]
      puts display_products(project, :invoice) if options[:invoice]
      puts display_costs(project)              if options[:costs] or fallback
      pp events_from_project(project)          if options[:cal]
      if options[:caterers]
        print "#{project.name}:".ljust(35)         if names.length > 1
        if project.data[:hours][:caterers]
          puts project.data[:hours][:caterers].map{|name, hours| "#{name} (#{hours})"}.join(", ")
        else
          puts "Caterers is empty"
        end
      end
    end
    }
  end

  desc "offer NAME", "Create an offer from project file."
    method_option :archive,
      :type=>:numeric, :aliases => "-a",
      :default => nil,
      :lazy_default=> Date.today.year,
      :required => false,
      :desc => "Open File from archive YEAR"
    method_option :stdout,
      :type=>:numeric, :aliases => "-s",
      :lazy_default=> true,
      :required => false,
      :desc => "print tex to stdout"
  def offer( *names)
    projects = open_projects names, options
    render_projects projects, :offer, options[:stdout]
  end

  desc "invoice NAME", "Create an invoice from project file."
    method_option :archive,
      :type=>:numeric, :aliases => "-a",
      :default => nil,
      :lazy_default=> Date.today.year,
      :required => false,
      :desc => "Open File from archive YEAR"
    method_option :stdout,
      :type=>:numeric, :aliases => "-s",
      :lazy_default=> true,
      :required => false,
      :desc => "print tex to stdout"
  def invoice( *names)
    projects = open_projects names, options
    render_projects projects, :invoice, options[:stdout]
  end






  desc "status", "Git Integration."
  def status
    if $PLUMBER.check_git()
      $PLUMBER.git_status()
    else
      puts "problems with git"
    end
  end


  desc "add NAME", "Git Integration."
  def add *names
    projects = open_projects names, options
    projects.each {|project|
      path = project.PROJECT_FOLDER
      if $PLUMBER.check_git()
        $PLUMBER.git_update_path(path)
      else
        puts "problems with git"
      end
    }
    status()
  end

  desc "commit message", "Git Integration."
  def commit message
    if $PLUMBER.check_git()
      $PLUMBER.git_commit(message)
    else
      puts "problems with git"
    end
  end

  desc "push", "Git Integration."
  def push
    if $PLUMBER.check_git()
      $PLUMBER.git_push()
    end
  end

  desc "pull", "Git Integration."
  def pull
    if $PLUMBER.check_git()
      $PLUMBER.git_pull()
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
    if $PLUMBER.check_git()
      $PLUMBER.git_log(options[:count])
    else
      puts "problems with git"
    end
  end





  desc "settings", "view Settings"
    method_option :edit,
      :type=>:boolean, :aliases => "-e",
      :lazy_default=> false,
      :required => false,
      :desc => "edit your settings"
    method_option :key,
      :type=>:array, :aliases => "-k",
      :required => false,
      :desc => "edit a specific settings value"
    method_option :show,
      :type=>:string, :aliases => "-s",
      :required => false,
      :desc => "show a specific settings value"
  def settings
    if options[:edit]
      if options[:key]
        key   = options[:key][0]
        value = options[:key][1]
        if $SETTINGS.keys.include? key
          $personal_settings[key] = value
          puts $personal_settings.to_yaml
        else
          puts "\"#{key}\" is no valid key in settings"
        end



      else
        path = $SETTINGS_PATHS[:global]
        if not File.exists? path and no? "There is no #{path} yet do you want to use a template? (YES/no)"
          error "templatefile #{$SETTINGS_PATHS[:template]} not found" unless File.exists? $SETTINGS_PATHS[:template]
          puts "ok, I copy over a template"
          FileUtils.cp($SETTINGS_PATHS[:template], path)
        end
        edit_files path
      end

    else
      if options[:show]
        if $SETTINGS.keys.include? options[:show]
          value = $SETTINGS[options[:show]]
          if value.class == Hash or value.class == Array
            puts value.to_yaml
          else
            puts value
          end
        else
          puts "\"#{options[:show]}\" is no valid key in settings"
        end
      else
        puts $SETTINGS.to_yaml
      end
      #pp $SETTINGS
    end
  end

  desc "path", "display projects storage path"
  def path
    puts File.join $SETTINGS['path'], $SETTINGS['dirs']['storage']
  end

  desc "version", "display Version"
  def version
    puts $SETTINGS['version'] unless options[:verbose]
    if options[:verbose]
      @git = Git.open File.join $SETTINGS['script_path'], ".."
      puts "ascii-invoicer: #{$SETTINGS['version']}"
      puts "#{RUBY_ENGINE}: #{RUBY_VERSION}"
      puts "commit: #{ @git.log.first.to_s }"
    end
  end
end

Commander.start
