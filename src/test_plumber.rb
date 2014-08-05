#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'yaml'
require './lib/tweaks'
require './lib/ProjectsPlumber'
require './lib/InvoiceProject'

settings_path = "default-settings.yml"
$SETTINGS = YAML::load File.open settings_path
$SETTINGS['path'] = "~/ascii/invoicer"
$SETTINGS['script_path'] = "~/code/ascii-invoicer/src/"


plumber = ProjectsPlumber.new $SETTINGS, InvoiceProject

plumber.open_projects
plumber.sort_projects :name

pp plumber["ASQF Juni"]
