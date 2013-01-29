#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
require 'paint'
require 'fileutils'
require './lib/invoicer.rb'
require './lib/minizen.rb'

@options = OpenStruct.new
@options.test = false
@options.path = './'
@options.editor = 'vim' 
@options.working_dir = "#{@options.path}projects/"
@options.template_dir= "#{@options.path}templates/"
@options.template= "#{@options.template_dir}vorlage.yaml"





## Checks the existens and creates folder if neccessarry
def check_projects_folder
  if File.exists? "#{@options.working_dir}/"
    return true
  else
    FileUtils.mkdir "#{@options.working_dir}/"
    puts "Created Projects Directory"
    return false
  end
end

def check_project name
  if File.exists?(project_file name)
    return true
  else
    puts Paint["file not found: \"#{project_file name}\"", :red]
    return false
  end
end

def project_folder name 
  "#{@options.working_dir}#{name}/"
end

def project_file name
  "#{project_folder name}#{name}.yml"
end

def tex_file name, type
  "#{project_folder name}#{name}-#{type.to_s}.tex"
end

def debug_info
  puts "Path Exists  #{@options.path} #{File.exists?(@options.path)}"
  puts "Template Exists  #{@options.template} #{File.exists?(@options.template)}"
  check_projects_folder()
end

## creates new project folder and file
def new_project(name)
  check_projects_folder

  unless File.exists? "#{@options.working_dir}/#{name}"
    FileUtils.mkdir "#{@options.working_dir}/#{name}"
    puts "Created Project Folder #{project_folder name}"
  end
  unless File.exists? project_file(name)
    FileUtils.cp @options.template, project_file(name)
    puts "Created Empty Project #{project_file name}"
  else
    puts "Project File exists.#{project_file name}"
    if confirm "Do you want to overwrite it?"
      FileUtils.cp @options.template, project_file(name)
    end
  end

  edit_file project_file name
end

## open project file from name
def open_project name
  edit_file project_file name if check_project name
end

## hand path to editor
def edit_file(path)
  puts "Opening #{path} in #{@options.editor}"
  exec "#{@options.editor} #{path}"
end

def write_tex(name, type)
  ## here comes the complicated code
  invoicer = Invoicer.new
  invoicer.load_templates :invoice => 'latex/ascii-rechnung.tex', :offer => 'latex/ascii-angebot.tex'
  invoicer.load_data project_file name

  tex = invoicer.fill type

  file = tex_file name, type
  f = File.new file, "w"

  tex.each do |line|
    f.write line
  end
  f.close
  puts "file writen: #{file}"
end

## OptionsParser
optparse = OptionParser.new do|opts|
  opts.on('-v','--vim FILENAME', 'opens file with vim') do |filename|
    exec "#{@options.editor} #{option.working_dir}/#{filename}"
  end

  opts.on( '-n', '--new NAME', 'Create new Project' ) do |name|
    new_project name
    exit
  end

  opts.on( '-i', '--invoice NAME', 'Create invoice from project' ) do |name|
    write_tex name, :invoice
    exit
  end

  opts.on( '-o', '--offer NAME', 'Create offer from project' ) do |name|
    write_tex name, :offer
    exit
  end

  opts.on( '-l', '--list', 'List all projects (not implemented)' ) do |name|
    puts name
    exit
  end

  opts.on( '-v', '--verbose', 'Be verbose (not implemented)' ) do |name|
    puts name
    exit
  end

  opts.on( '--close NAME', 'Close project (not implemented)' ) do |name|
    puts name
    exit
  end

  opts.on( '--clean NAME', 'Removes everything but the project file (not implemented)' ) do |name|
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

## Use Option parser or leave it if only one argument is given
if ARGV.size == 1 and ARGV[0][0] != '-'
  pp "ARGV:", ARGV
  open_project ARGV[0]
else
  optparse.parse!
end
