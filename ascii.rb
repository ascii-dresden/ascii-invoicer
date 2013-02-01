#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
require 'paint'
require 'fileutils'
require './lib/object.rb'
require './lib/invoicer.rb'
require './lib/minizen.rb'
require './lib/options.rb'

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

## path to project file
def project_file name
  "#{project_folder name}#{name}.yml"
end

## path to tex file
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
def open_project_by_number number 
  open_project list_projects[number-1]
end

## open project file from name
def open_project name
  edit_file project_file name if check_project name
end

## list projects
def list_projects
  dir = Dir.entries(@options.working_dir).delete_if { |v| v[0] == '.' }
  dir

end

## hand path to editor
def edit_file(path)
  puts "Opening #{path} in #{@options.editor}"
  exec "#{@options.editor} #{path}"
end

## hand path to latex tool
def render_tex(path)
  puts "Rendering #{path} with #{@options.latex}"
  spawn "#{@options.latex} #{path} -output-directory ." #TODO output directory is not generic
end

def write_tex(name, type)
  invoicer = Invoicer.new

  invoicer.load_templates :invoice => @options.template_invoice , :offer => @options.template_offer
  invoicer.load_data project_file name

  invoicer.type = type
  invoicer.project_name = name

  if invoicer.is_valid or true
    tex = invoicer.create
    
    pp invoicer.dump

    file = tex_file name, type
    #  f = File.new file, "w"
    #
    #  tex.each do |line|
    #    f.write line
    #  end
    #  f.close
    #  puts "file writen: #{file}"
    file
  else
    puts "invoice is not valid"
  end
end

## OptionsParser
optparse = OptionParser.new do|opts|

  opts.banner = "Usage: ascii.rb [name|number] or ascii.rb [options]"


  opts.on('-v','--vim FILENAME', 'opens file with vim') do |filename|
    exec "#{@options.editor} #{option.working_dir}/#{filename}"
  end

  opts.on( '-n', '--new NAME', 'Create new Project' ) do |name|
    new_project name
    exit
  end

  opts.on( '-i', '--invoice NAME', 'Create invoice from project' ) do |name|
    tex = write_tex name, :invoice
    #render_tex tex
    exit
  end

  opts.on( '-o', '--offer NAME', 'Create offer from project' ) do |name|
    tex = write_tex name, :offer
    #render_tex tex
    exit
  end

  opts.on( '-l', '--list', 'List all projects (not implemented)' ) do |name|
    projects = list_projects
    projects.each_index do |i|
      puts "#{i+1} #{projects[i]} "
    end
    exit
  end

  opts.on( '-v', '--verbose', 'Be verbose (not implemented)' ) do |name|
    puts "-v  not yet implemented -- sorry"
    exit
  end

  opts.on( '--close NAME', 'Close project (not implemented)' ) do |name|
    puts "--close not yet implemented -- sorry"
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
  pp ARGV
  unless ARGV[0].to_i == 0
    open_project_by_number ARGV[0].to_i
  end
  open_project ARGV[0]
  
else
  optparse.parse!
end
