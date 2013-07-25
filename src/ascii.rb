#!/usr/bin/env ruby
# encoding: utf-8

require 'paint'
require 'thor'
$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]

require "#{$SCRIPT_PATH}/lib/object.rb"
require "#{$SCRIPT_PATH}/lib/invoicer.rb"
require "#{$SCRIPT_PATH}/lib/minizen.rb"
require "#{$SCRIPT_PATH}/lib/options.rb"
require "#{$SCRIPT_PATH}/lib/plumber.rb"
require "#{$SCRIPT_PATH}/lib/ascii_invoicer.rb"

class Commander < Thor
  include Thor::Actions
  include AsciiInvoicer

  package_name "ascii invoicer"
  #argument :first, :type => :numeric
  map "-l" => :list

  class_option :verbose, :aliases=> "-v", :type => :boolean
  class_option "keep-log", :aliases=> "-k", :type => :boolean


  desc "new FILE", "creating a new project" 
  def new(name)
    @plumber = ProjectsPlumber.new $settings
    puts "creating a new project name #{name}"
    edit_file @plumber.new_project name
  end




  desc "list", "List current Projects."
  method_option :archives,
    :type=>:string, :aliases => "-a",
    :lazy_default=> Date.today.year.to_s,
    :required => false,
    :desc => "List archived Projects"

  def list
    unless options[:archives]
      @plumber = ProjectsPlumber.new $settings
      projects = @plumber.working_projects
      #print_project_list_colored(projects)
      print_project_list_colored(projects)
    else
      $settings.archive_year = options[:archives]
      $settings.read_archive = true
      
      @plumber = ProjectsPlumber.new $settings
      projects = @plumber.working_projects
      print_project_list(projects)
    end
  end




  desc "help", "overwriting default help."
  def help()
    puts "here is my default command"
  end




  desc "show NAME", "Show information about the project."
  def show(name)
    @plumber = ProjectsPlumber.new $settings

    project = @plumber.pick_project name
    file    = @plumber.get_project_file project
    data    = @plumber.open_project file
    puts "\"#{data['event']}\":".ljust(30) + "#{data['summe'].rjust 8}"
    puts "MORE TO COME"
  end




  desc "edit NAME", "Edit project file."
  def edit(name)
    # TODO implement edit --archive
    @plumber = ProjectsPlumber.new $settings
    project = @plumber.pick_project name
    edit_file @plumber.get_project_file_path project
  end




  desc "offer NAME", "Create an offer from project file."
  def offer(name)
    # TODO implement offer --archive
    @plumber = ProjectsPlumber.new $settings
    puts @plumber.pick_project name
  end




  desc "invoice NAME", "Create an invoice from project file."
  def invoice(name)
    # TODO implement invoice --archive
    @plumber = ProjectsPlumber.new $settings
    puts @plumber.pick_project name
  end




  desc "archive NAME", "Move project to archive."
  def archive(name)
    # TODO implement archive Project
    @plumber = ProjectsPlumber.new $settings

    if yes? "Sicher? [Yes|No]"
      puts @plumber.pick_project name
      puts "NOT YET IMPLEMENTED"
    else
      puts "ok, so not"
    end
  end




  desc "reopen NAME", "Opposite of \"archive\"."
  def reopen(name)
    puts @plumber.pick_project name
    puts "NOT YET IMPLEMENTED"
  end

end

Commander.start
