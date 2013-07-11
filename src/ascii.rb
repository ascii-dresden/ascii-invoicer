#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
require 'paint'
require 'thor'
require 'fileutils'
$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]

require "#{$SCRIPT_PATH}/lib/object.rb"
require "#{$SCRIPT_PATH}/lib/invoicer.rb"
require "#{$SCRIPT_PATH}/lib/minizen.rb"
require "#{$SCRIPT_PATH}/lib/options.rb"
require "#{$SCRIPT_PATH}/lib/plumber.rb"
require "#{$SCRIPT_PATH}/lib/ascii_invoicer.rb"

class Commander < Thor

  package_name "ascii invoicer"
  #argument :first, :type => :numeric

  class_option :verbose, :aliases=> "-v", :type => :boolean

  desc "new FILE", "creating a new project" 
  def new(file)
    puts "creating a new project name #{file}"
  end

  desc "list", "List current Projects"
  method_option :archives, :type=>:numeric, :aliases => "-a", :lazy_default=> Date.today.year, :required => false, :desc => "List archived Projects"
  def list
    unless options[:archives]
      print_project_list()
    else
      puts "now listing archived projects" , options[:archives]
    end
  end

  desc "show NAME", "Show information about the project"
  def show(name)
    puts name
    puts @plumber.pick_project name
  end

  #desc "hello NAME", "say hello to NAME"
  #options :from => :required, :yell => :boolean
  #def hello(name)
  #  puts "> saying hello" if options[:verbose]
  #  output = []
  #  output << "from: #{options[:from]}" if options[:from]
  #  output << "Hello #{name}"
  #  output = output.join("\n")
  #  puts options[:yell] ? output.upcase : output
  #  puts "> done saying hello" if options[:verbose]
  #end

  desc "test","test task"
  def test
    puts @plumber.dirs
  end

  no_commands {

    def initialize(*args)
      super
      @plumber = ProjectsPlumber.new $settings
    end

    def start
      puts "thor initialized"
    end

    ## hand path to editor
    def edit_file(path)
      puts "Opening #{path} in #{$settings.editor}"
      pid = spawn "#{$settings.editor} #{path}"
      Process.wait pid
    end

    def print_project_list
      projects = @plumber.working_projects
      projects.each_index do |i|
        invoice   = projects[i]


        number    = (i+1).to_s
        name      = invoice['name']
        signature = invoice['signature']
        rnumber   = invoice['rnumber']
        rnumber   = "R" + rnumber.to_s.rjust(3,'0') if rnumber.class == Fixnum
        date      = invoice['date']

        number    = number.rjust 4
        name      = name.ljust 34
        signature = signature.ljust 17
        rnumber   = rnumber.to_s.ljust 4
        date      = date.rjust 15

        number    = Paint[number, :bright]
        name      = Paint[name, [145,145,145], :clean] if invoice['raw_date'].to_date <= Date.today
        name      = Paint[name, [255,0,0], :bright ]   if invoice['raw_date'].to_date - Date.today < 7
        name      = Paint[name, [255,255,0] ]          if invoice['raw_date'].to_date - Date.today < 14
        name      = Paint[name, [0,255,0] ]            if invoice['raw_date'].to_date - Date.today >= 14
        signature = signature
        rnumber   = rnumber
        date      = date

        line = "#{number}. #{name} #{signature} #{rnumber} #{date}"



        puts line
        #unless projects[i+1].nil?
        #  if invoice['raw_date'] <= Time.now and projects[i+1]['raw_date'] > Time.now
        #    padding = Paint.unpaint(number).length + 3
        #    plain_line = Paint.unpaint line
        #    divider = ''.rjust(padding).ljust(plain_line.length-padding, '█')
        #    puts divider
        #  end
        #end
        #puts "R#{invoice['rnumber'].to_s}, #{invoice['name']}, #{invoice['signature']}, #{invoice['date']}"
      end
    end

  }


end

Commander.start

