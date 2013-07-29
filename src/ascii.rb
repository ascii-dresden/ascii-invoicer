#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'thor'
require 'paint'
require 'yaml'

$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]
$SETTINGS = YAML::load(File.open("#{$SCRIPT_PATH}/default-settings.yml"))
$local_settings = YAML::load(File.open("settings.yml")) if File.exists? "settings.yml"
#$SETTINGS['path'] = $SCRIPT_PATH

require "#{$SCRIPT_PATH}/lib/invoicer.rb"
require "#{$SCRIPT_PATH}/lib/minizen.rb"
require "#{$SCRIPT_PATH}/lib/plumber.rb"
require "#{$SCRIPT_PATH}/lib/ascii_invoicer.rb"


# bootstraping
@plumber = ProjectsPlumber.new $SETTINGS
@plumber.create_dir :storage unless @plumber.check_dir :storage
@plumber.create_dir :working unless @plumber.check_dir :working
@plumber.create_dir :archive unless @plumber.check_dir :archive



# $SETTINGS
def overwrite_settings(default, custom)
  default.each do |k,v|
    if custom[k].class == Hash
      overwrite_settings default[k], custom[k]
    else
      default[k] = custom[k] unless custom[k].nil?
    end
  end
end

if $local_settings
  overwrite_settings $SETTINGS, $local_settings
end


class Commander < Thor
  include Thor::Actions
  include AsciiInvoicer

  package_name "ascii invoicer"
  #argument :first, :type => :numeric
  map "-l" => :list

  class_option :file,      :aliases=> "-f", :type => :boolean
  class_option :verbose,   :aliases=> "-v", :type => :boolean
  class_option "keep-log", :aliases=> "-k", :type => :boolean
  class_option "colors",   :aliases=> "-c", :type => :boolean


  desc "new NAME", "creating a new project" 
  def new(name)
    @plumber = ProjectsPlumber.new $SETTINGS
    if @plumber.new_project name
      puts "creating a new project name #{name}"
    else
      #puts "Project #{name} already exists"
      edit_file @plumber.get_project_file_path name
    end
  end


  desc "settings", "view Settings"
  def settings
    pp $SETTINGS
    pp $local_settings
  end


  #desc "list", "List current Projects."
  #method_option :archives,
  #  :type=>:string, :aliases => "-a",
  #  :lazy_default=> Date.today.year.to_s,
  #  :required => false,
  #  :desc => "List archived Projects"
  #def list
  #  unless options[:archives]
  #    @plumber = ProjectsPlumber.new $SETTINGS
  #    projects = @plumber.working_projects
  #    #print_project_list_colored(projects)
  #    print_project_list_colored(projects)
  #  else
  #    $SETTINGS.archive_year = options[:archives]
  #    $SETTINGS.read_archive = true
  #    
  #    @plumber = ProjectsPlumber.new $SETTINGS
  #    projects = @plumber.working_projects
  #    print_project_list(projects)
  #  end
  #end




  desc "archive NAME", "Move project to archive."
  def archive(name)
    # TODO implement archive Project
    @PLUMBER = ProjectsPlumber.new $SETTINGS

    if yes? "Sicher? [Yes|No]"
      puts @plumber.pick_project name
      puts "NOT YET IMPLEMENTED"
    else
      puts "ok, so not"
    end
  end




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




  #desc "edit NAME", "Edit project file."
  #def edit(name)
  #  # TODO implement edit --archive
  #  @plumber = ProjectsPlumber.new $SETTINGS
  #  project = @plumber.pick_project name
  #  edit_file @plumber.get_project_file_path project
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
