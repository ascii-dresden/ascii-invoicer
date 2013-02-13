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
  if File.exists? "#{@options.working_dir}"
    return true
  else
    FileUtils.mkdir "#{@options.working_dir}"
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

def close_project name
  # TODO rename folders
  FileUtils.mkdir @options.done_dir unless(File.exists? @options.done_dir)
  FileUtils.mv "#{@options.working_dir}#{name}", @options.done_dir if check_project name
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
def get_project input
  if (number = input.to_i) != 0
    @options.projectname = list_projects[number-1]
  else
    @options.projectname = input
  end
end

## open project file from name
def edit_project name
  edit_file project_file name if check_project name
end

## hand path to editor
def edit_file(path)
  puts "Opening #{path} in #{@options.editor}"
  pid = spawn "#{@options.editor} #{path}"
  Process.wait pid
end

## list projects
def list_projects
  check_projects_folder
  dir = Dir.entries(@options.working_dir).delete_if { |v| v[0] == '.' }
  dir
end

## pretty version list projects TODO: make prettier
def print_project_list
    projects = list_projects
    projects.each_index do |i|
      puts "#{i+1} #{projects[i]} "
    end
end

## creates a  latex file from NAME of the desired TYPE
def write_tex(name, type)
  return false unless check_project name
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
      filename = "R#{d['rnumber']} #{name} #{datestr}.tex"
      file = "#{project_folder name}"+filename
    when :offer
      datestr = d['raw_date'].strftime("%y%m%d")
      filename = "#{datestr} Angebot #{name}.tex"
      file = "#{project_folder name}"+filename
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
    unless @options.keep_log
      FileUtils.rm filename.gsub('.tex','.log')
      FileUtils.rm filename.gsub('.tex','.aux')
    end
  else
    puts "invoice is not valid"
  end
end


## Use Option parser or leave it if only one argument is given
if ARGV.size == 0
  projects = list_projects
  projects.each_index do |i|
    puts "#{i+1} #{projects[i]} "
  end
else
  @options.projectname = ARGV[0] if ARGV[0][0] != '-'
  @optparse.parse!
  @options.projectname = get_project @options.projectname
  pp @options.operations, @options.projectname, {verbose:@options.verbose} if @options.verbose

  @options.operations = [:edit] if @options.operations.size == 0
  project = @options.projectname
  operations = @options.operations

  edit_project project        if operations.include? :edit
  write_tex project, :invoice if operations.include? :invoice
  write_tex project, :offer   if operations.include? :offer
  print_project_list          if operations.include? :list
  close_project project       if operations.include? :close
  new_project project         if operations.include? :new

end
