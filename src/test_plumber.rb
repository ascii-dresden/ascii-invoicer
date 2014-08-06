#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'
require 'csv'
require 'yaml'
require './lib/ProjectsPlumber'
require './lib/InvoiceProject'
require './lib/Textboxes'

require './lib/ascii_invoicer'
require './lib/tweaks'

settings_path = "default-settings.yml"
$SETTINGS = YAML::load File.open settings_path
$SETTINGS['path'] = "~/ascii/invoicer"
$SETTINGS['script_path'] = "~/code/ascii-invoicer/src/"

include AsciiInvoicer

plumber = ProjectsPlumber.new $SETTINGS, InvoiceProject

plumber.open_projects
plumber.sort_projects :name

projects = plumber.opened_projects

#print_project_list_simple  projects
#print_project_list_verbose projects
#print_project_list_paths   projects
#print_project_list_yaml    projects
#print_project_list_csv     projects # TODO

projects[1].data[:products].each{|p|
  pp p.tax
}
