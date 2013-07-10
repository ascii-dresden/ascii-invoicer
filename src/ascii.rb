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
      puts "now listing current projects"
    else
      puts "now listing archived projects" , options[:archives]
    end
  end

  desc "show NAME", "Show information about the project"
  def show

  end

  desc "hello NAME", "say hello to NAME"
  options :from => :required, :yell => :boolean
  def hello(name)
    puts "> saying hello" if options[:verbose]
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
    puts "> done saying hello" if options[:verbose]
  end

  desc "default NUMBER","default blub"
  def default
    puts options
  end

end

Commander.start




#ascii = AsciiInvoicer.new @options
#ascii.execute()
