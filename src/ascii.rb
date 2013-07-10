#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
require 'paint'
require 'fileutils'
$SCRIPT_PATH = File.split(File.expand_path(File.readlink(__FILE__)))[0]

require "#{$SCRIPT_PATH}/lib/object.rb"
require "#{$SCRIPT_PATH}/lib/invoicer.rb"
require "#{$SCRIPT_PATH}/lib/minizen.rb"
require "#{$SCRIPT_PATH}/lib/options.rb"
require "#{$SCRIPT_PATH}/lib/plumber.rb"
require "#{$SCRIPT_PATH}/lib/ascii_invoicer.rb"


# direkt naming
@options.projectname = ARGV[0] if ARGV.size > 0 and ARGV[0][0] != '-'
@optparse.parse!


ascii = AsciiInvoicer.new @options
ascii.execute()
