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
    # TODO: create it?
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


def debug_info
  puts "Path Exists  #{@options.path} #{File.exists?(@options.path)}"
  puts "Template Exists  #{@options.template_yml} #{File.exists?(@options.template_yml)}"
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
    FileUtils.cp @options.template_yml, project_file(name)
    puts "Created Empty Project #{project_file name}"
  else
    puts "Project File exists.#{project_file name}"
    if confirm "Do you want to overwrite it?"
      FileUtils.cp @options.template_yml, project_file(name)
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
  check_projects_folder
  dir = Dir.entries(@options.working_dir).delete_if { |v| v[0] == '.' }
  dir
end

def print_project_list
    projects = list_projects
    projects.each_index do |i|
      puts "#{i+1} #{projects[i]} "
    end
end

## hand path to editor
def edit_file(path)
  puts "Opening #{path} in #{@options.editor}"
  pid = spawn "#{@options.editor} #{path}"
  Process.wait pid
end


## creates a  latex file from NAME of the desired TYPE
def write_tex(name, type)
  invoicer = Invoicer.new

  invoicer.load_templates :invoice => @options.template_invoice , :offer => @options.template_offer
  invoicer.load_data project_file name

  invoicer.type = type
  invoicer.project_name = name

  if invoicer.is_valid or true
    tex = invoicer.create

    d = invoicer.dump

    case type
    when :invoice
      datestr = d['raw_date'].strftime("%Y-%m-%d")
      file = "#{project_folder name}R#{d['rnumber']} #{name} #{datestr}.tex"
    when :offer
      datestr = d['raw_date'].strftime("%y%m%d")
      file = "#{project_folder name}#{datestr} Angebot #{name}.tex"
    end

    pp file
    f = File.new file, "w"

    tex.each do |line|
      f.write line
    end
    f.close
    puts "file writen: #{file}"
    file

    puts "Rendering #{file} with #{@options.latex}"
    silencer = @options.verbose ? "" : "> /dev/null" 
    system "#{@options.latex} \"#{file}\" -output-directory . #{silencer}" #TODO output directory is not generic
  else
    puts "invoice is not valid"
  end
end


## Use Option parser or leave it if only one argument is given
if ARGV.size == 1 and ARGV[0][0] != '-'
  pp ARGV
  unless ARGV[0].to_i == 0
    open_project_by_number ARGV[0].to_i
  else
    open_project ARGV[0]
  end
else
  if ARGV.size == 0
    projects = list_projects
    projects.each_index do |i|
      puts "#{i+1} #{projects[i]} "
    end
  else
    @optparse.parse!
  end
end
