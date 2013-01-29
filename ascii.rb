#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
require 'fileutils'
require './lib/invoicer.rb'

@options = OpenStruct.new
@options.test = false
@options.path = './'
@options.editor = 'vim' 
@options.working_dir = "#{@options.path}projects/"
@options.template_dir= "#{@options.path}templates/"
@options.template= "#{@options.template_dir}vorlage.yaml"




invoicer = Invoicer.new
invoicer.load_templates :invoice => 'latex/ascii-rechnung.tex', :offer => 'latex/ascii-angebot.tex'

def check_project name
  path = "#{@options.working_dir}#{name}#{name}.yml" #TODO Find an nameingscheme for files
  return path if File.exists? path
end

## Checks the existens and creates folder if neccessarry
def check_projects_folder
  if not File.exists? "#{@options.working_dir}/"
    FileUtils.mkdir "#{@options.working_dir}/"
    puts "Created Projects Directory"
  end
end

def debug_info
  puts "Path Exists  #{@options.path} #{File.exists?(@options.path)}"
  puts "Template Exists  #{@options.template} #{File.exists?(@options.template)}"
  check_projects_folder()
end


def new_project(name)
  check_projects_folder
  project_folder= "#{@options.working_dir}#{name}"
  project_file  = "#{project_folder}#{name}.yml"
  unless File.exists? "#{@options.working_dir}/#{name}"
    FileUtils.mkdir "#{@options.working_dir}/#{name}"
    puts "Created Project Folder #{project_folder}"
  end
  unless File.exists? project_file
    FileUtils.cp @options.template, project_file
    puts "Created Empty Project #{project_file}"
  end
  
  edit_file project_file

end

def edit_file(path)
  puts "Opening #{path} in #{@options.editor}"
  exec "#{@options.editor} #{path}"
end


optparse = OptionParser.new do|opts|
  opts.on('-t', 'test feature, set this first') do |test|
    @options.test = true
  end
  opts.on('-v','--vim FILENAME', 'opens file with vim') do |filename|
    exec "#{@options.editor} #{option.working_dir}/#{filename}"
  end
  opts.on( '-n', '--new NAME', 'Create new Project' ) do |name|
    new_project name
    exit
  end
  opts.on( '-i', '--invoice NAME', 'Create invoice from project (not implemented)' ) do |name|
    puts name
    exit
  end
  opts.on( '-o', '--offer NAME', 'Create offer from project (not implemented)' ) do |name|
    puts name
    exit
  end
  opts.on( '-a', 'Legacy option creating an offer from FILE (not implemented)' ) do |filename|
    puts name
    exit
  end
  opts.on( '-r', 'Legacy option creating an invoice from FILE (not implemented)' ) do |filename|
    puts name
    exit
  end
  opts.on('-c', '--check', "Show Debug information") do
    debug_info()
    exit
  end

  opts.on_tail( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

if ARGV.size == 1 and ARGV[0][0] != '-'
  pp "ARGV:", ARGV
else
  optparse.parse!
end
