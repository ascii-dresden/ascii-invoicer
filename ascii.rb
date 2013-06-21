#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'
#require 'paint'
require 'fileutils'
require './lib/object.rb'
require './lib/invoicer.rb'
require './lib/minizen.rb'
require './lib/options.rb'

### Plumbing

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
  return true if not @options.project_file.nil? and File.exists?(@options.project_file) 

  if File.exists?(get_project_file name)
    return true
  else
    #puts Paint["file not found: \"#{get_project_file name}\"", :red]
    puts "file not found: \"#{get_project_file name}\""
    # TODO: create it?
    return false
  end
end

def get_project_folder name 
  "#{@options.working_dir}#{name}/"
end

## path to project file
def get_project_file name
  if @options.project_file.nil?
    files = Dir.glob("#{get_project_folder name}*.yml")
    fail "ambiguous amount of yml files in #{file}" if files.length != 1
    return files[0]
  else
    @options.project_file
  end
end


def debug_info
  puts "Path Exists  #{@options.path} #{File.exists?(@options.path)}"
  puts "Template Exists  #{@options.template_yml} #{File.exists?(@options.template_yml)}"
  check_projects_folder()
end








### Project life cycle
## creates new project folder and file
def new_project(name)
  check_projects_folder

  unless File.exists? "#{@options.working_dir}/#{name}"
    FileUtils.mkdir "#{@options.working_dir}/#{name}"
    puts "Created Project Folder #{get_project_folder name}"
  end
  unless File.exists? get_project_file(name)
    FileUtils.cp @options.template_yml, get_project_file(name)
    puts "Created Empty Project #{get_project_file name}"
  else
    puts "Project File exists.#{get_project_file name}"
    if confirm "Do you want to overwrite it?"
      FileUtils.cp @options.template_yml, get_project_file(name)
    end
  end

  edit_file get_project_file name
end

## Move to archive directory
def close_project name
  # TODO rename folders
  invoicer = Invoicer.new
  invoicer.read_file get_project_file name
  invoicer.mine
  invoice = invoicer.dump
  rn  =  !invoice['rnumber'].nil? ? invoice['rnumber'] : "_"
  year = invoice['raw_date'].year
  FileUtils.mkdir @options.done_dir unless(File.exists? @options.done_dir)
  FileUtils.mkdir "#{@options.done_dir}/#{year}" unless(File.exists? @options.done_dir)
  FileUtils.mv "#{@options.working_dir}#{name}", "#{@options.done_dir}R#{rn}-#{year}-#{name}" if check_project name
end







## open project file from name
def pick_project input
  if (number = input.to_i) != 0
    @options.projectname = list_projects[number-1]
  else
    @options.projectname = input
  end
end

## open project file from name
def edit_project name
  edit_file get_project_file name if check_project name or not @options.project_file.nil?
end

## hand path to editor
def edit_file(path)
  puts "Opening #{path} in #{@options.editor}"
  pid = spawn "#{@options.editor} #{path}"
  Process.wait pid
end

def get_dump(path)
  invoicer = Invoicer.new

  invoicer.load_templates :invoice => @options.template_invoice , :offer => @options.template_offer
  invoicer.read_file get_project_file path
  invoicer.mine
  invoicer.dump
end

def dump_file(path)
  pp get_dump path
end

def sum_up(path)
  dump = get_dump path
  picks = ['event', 'summe', 'date',
  ]

  pp dump.keep_if { |k,v| picks.include? k and not v.nil? }
end




## TODO FIXME XXX
def open_project file # or folder ??
  case File.ftype file
    when 'file' then
      invoicer = Invoicer.new
      invoicer.read_file file
      invoicer.mine()
      invoicer.dump
    when 'directory' then
      files = Dir.glob file+'/*.yml'
      fail "ambiguous amount of yml files in #{file}" if files.length != 1
      open_project files[0]
    else
      fail "Unexpected Filetype"
    end
end


## list projects
def parse_projects
  check_projects_folder
  dirs = Dir.entries(@options.working_dir).delete_if { |v| v[0] == '.' }
  @projects= []
  dirs.each_index do |i|
    invoice  = open_project get_project_file dirs[i]
    invoice['name'] = dirs[i]
    invoice['rnumber'] =  !invoice['rnumber'].nil? ? invoice['rnumber'] : "_"
    @projects.push invoice
    #puts "#{i+1} #{projects[i].ljust 25} #{invoice['signature'].ljust 17} R#{invoice['rnumber'].to_s.ljust 3} #{invoice['date']}"
  end
  @projects.sort_by! { |invoice| invoice['raw_date'] }
end

## list projects
def list_projects
  parse_projects if @projects.nil?
  dir = []
  @projects.each { |invoice|
    dir.push invoice['name']
  }
  dir
end

## pretty version list projects TODO: make prettier
def print_project_list
  parse_projects if @projects.nil?
  @projects.each_index do |i|
    invoice = @projects[i]
    puts "#{(i+1).to_s.rjust 3} #{invoice['name'].ljust 25} #{invoice['signature'].ljust 17} R#{invoice['rnumber'].to_s.ljust 3} #{invoice['date'].rjust 13}"
    unless @projects[i+1].nil?
      puts "    ".ljust(66,'-') if invoice['raw_date'] <= Time.now and @projects[i+1]['raw_date'] > Time.now
    end
    #puts "R#{invoice['rnumber'].to_s}, #{invoice['name']}, #{invoice['signature']}, #{invoice['date']}"
  end
end

## creates a  latex file from NAME of the desired TYPE
def write_tex(name, type)
  return false unless check_project name
  invoicer = Invoicer.new

  invoicer.load_templates :invoice => @options.template_invoice , :offer => @options.template_offer
  invoicer.read_file get_project_file name

  invoicer.type = type
  invoicer.project_name = name

  if invoicer.is_valid or true
    tex = invoicer.create

    d = invoicer.dump

    # datei namen
    case type
    when :invoice
      datestr = d['raw_date'].strftime("%Y-%m-%d")
      filename = "R#{d['rnumber'].to_s.rjust 3, "0"} #{name} #{datestr}.tex"
      file = "#{get_project_folder name}"+filename
    when :offer
      datestr = d['raw_date'].strftime("%y%m%d")
      filename = "#{datestr} Angebot #{name}.tex"
      file = "#{get_project_folder name}"+filename
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
  @projects = parse_projects
  @dirs = list_projects
  print_project_list
else

  @options.projectname = ARGV[0] if ARGV[0][0] != '-'
  @optparse.parse!
  @options.projectname = pick_project @options.projectname
  pp @options.operations, @options.projectname, {:verbose => @options.verbose} if @options.verbose

  @options.operations = [:edit] if @options.operations.size == 0
  project = @options.projectname
  operations = @options.operations

  edit_project project        if operations.include? :edit
  write_tex project, :invoice if operations.include? :invoice
  write_tex project, :offer   if operations.include? :offer
  print_project_list          if operations.include? :list
  close_project project       if operations.include? :close
  new_project project         if operations.include? :new
  dump_file project           if operations.include? :dump
  sum_up project              if operations.include? :sum

end
