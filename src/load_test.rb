#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'yaml'
require 'paint'
require './lib/tweaks'
require './lib/Euro'
require './lib/InvoiceProject'

settings_path = "default-settings.yml"
$SETTINGS = YAML::load File.open settings_path
$SETTINGS['script_path'] = __FILE__

#path =  'spec/test_projects/alright.yml'
path =  "/home/hendrik/ascii/invoicer/caterings/archive/2014/R027_Baldauf Mittagsbroetchen/Baldauf Mittagsbroetchen.yml"
path = "/home/hendrik/ascii/invoicer/caterings/working/AMBI-Workshop/AMBI-Workshop.yml"

project = InvoiceProject.new $SETTINGS, path

#puts project.parse :script_path
#project.validate :invoice , true
project.validate :offer
pp project.data :products

#puts project.data[:products]
#puts project.parse :products

pp project.valid_for
pp project.errors

