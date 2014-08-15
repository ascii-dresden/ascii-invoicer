# encoding: utf-8
require 'fileutils'

libpath = File.dirname __FILE__
require File.join libpath, "gitplumber.rb"
require File.join libpath, "AsciiSanitizer.rb"
require File.join libpath, "shell.rb"


## requires a project_class
# project_class must implement: name, date
class ProjectsPlumber

  attr_reader :dirs,
    :opened_projects,
    :project_paths,
    :opened_paths,
    :opened_sort,
    :opened_dir

  attr_writer :project_class

  include GitPlumber
  include Shell


  def initialize(settings = $SETTINGS, project_class = nil)
    @settings        = settings
    @opened_projects = []
    @project_class   = project_class
    @file_extension  = settings['project_file_extension']

    error "need a project_class" if project_class.nil?

    @dirs            = {}
    @dirs[:template] = File.expand_path File.join @settings['script_path'], @settings['templates']['project']
    @dirs[:storage]  = File.expand_path File.join @settings['path'], @settings['dirs']['storage']
    @dirs[:working]  = File.join @dirs[:storage], @settings['dirs']['working']
    @dirs[:archive]  = File.join @dirs[:storage], @settings['dirs']['archive']
  end

  ##
  # *wrapper* for puts()
  # depends on @settings.silent = true|false
  def logs string
  end

  ##
  # Checks the existens of one of the three basic dirs.
  # dir can be either :storage, :working or :archive
  # and also :template
  def check_dir(dir)
    File.exists? "#{@dirs[dir]}"
  end

  ##
  # Checks the existens of every thing required
  def check_dirs
    check_dir :storage and
    check_dir :working and
    check_dir :archive and
    check_dir :template
  end

  ##
  # create a dir
  # dir can be either :storage, :working or :archive
  def create_dir(dir)
    unless check_dir(dir)
      if dir == :storage or check_dir :storage
        FileUtils.mkdir "#{@dirs[dir]}"
        logs "Created \"#{dir.to_s}\" Directory (#{@dirs[dir]})"
        return true
      end
      logs "no storage dir"
    end
    false
  end
 
  ##
  # creates new project_dir and project_file
  def _new_project_folder(name)
    unless check_dir(:working)
      logs(File.exists? @dirs[:working])
      logs "missing working directory!"
      return false
    end

    #  check of existing project with the same name
    folder = get_project_folder(name, :working)
    unless folder
      FileUtils.mkdir File.join @dirs[:working], name
      return get_project_folder(name, :working)
    else
      logs "#{folder} already exists"
      return false
    end
  end

  ##
  # creates new project_dir and project_file
  # returns project object
  def new_project(_name)
    _name = AsciiSanitizer.process _name
    name = AsciiSanitizer.clean_path _name

    project_name   = _name
    settings       = @settings
    defaults       = @settings['defaults']
    defaults       = {}

    filename = @dirs[:template]

    ## Approach A ( Thomas Kühn )
    engine=ERB.new(File.read(filename),nil,'<>')
    result = engine.result(binding)

    # copy template_file to project_dir
    folder = _new_project_folder(name)
    if folder
      target = File.join folder, name+@file_extension

      #puts "writing into #{target}"
      file = File.new target, "w"
      result.lines.each do |line|
        file.write line
      end
      file.close

      logs "#{folder} created"
      return @project_class.new target
    else
      return false
    end
  end


  ##
  # produces an Array of @project_class objects
  # sorted by date (projects must implement date())
  # if sort is foobar, projects must implement foobar()
  # output of (foobar must be comparable)
  #
  # untested
  def open_projects(dir=:working, year=Date.today.year, sort = :date)
    if dir==:all
      @opened_paths    = list_projects_all
    else
      @opened_paths    = list_projects dir, year 
    end

    @opened_dir      = dir
    @project_paths   = {}
    @opened_paths.each {|path|
      project = @project_class.new path
      if project.STATUS != :unparsable
        @opened_projects = @opened_projects + [ project ]
      end
      @project_paths[project.name] = path
    }
    sort_projects(sort)
    return true
  end

  def open_project project
    if project.class == String
      project = AsciiSanitizer.process    project
      project = AsciiSanitizer.clean_path project
      open_projects()
      project = lookup(project)
    end
    return project if project.class == @project_class
  end


  ##
  # produces an Array of @project_class objects
  #
  # untested
  def open_projects_all(sort = :date)
    @opened_paths    = list_projects_all
    open_projects :all, year=nil, sort
  end

  def [] name
    lookup name
  end

  def lookup_path(name, sort = nil)
    p = lookup(name)
    return @project_paths[p.name] unless p.nil?
    puts "there is no project #{name}"
  end
  
  
  def lookup(name, sort = nil)
    sort_projects sort unless sort == nil or @opened_sort == sort
    name = name.to_i - 1 if name =~ /^\d*$/
    if name.class == String
      name_map = {}
      @opened_projects.each {|project| name_map[project.name] = project}
      project = name_map[name]
      error "there is no project \"#{name}\"" if project.nil?
    elsif name.class == Fixnum
      project =  @opened_projects[name]
      error "there is no project ##{name+1}" if project.nil?
    end
    return project
  end
  
  
  def sort_projects(sort = :date)
      fail "sort must be a Symbol" unless sort.class == Symbol
      if @project_class.method_defined? sort
          @opened_projects.sort_by! {|project| project.method(sort).call}
      else fail "#{@project_class} does not implement #{sort}()"
      end
      return true
  end
  
  ##
  # path to project file
  # there may only be one @file_extension file per project folder
  #
  # untested
  def get_project_file_path(name, dir=:working, year=Date.today.year)
      name = AsciiSanitizer.process    name
      name = AsciiSanitizer.clean_path name
      
    folder = get_project_folder(name, dir, year)
    if folder
      files = Dir.glob File.join folder, "*#{@file_extension}"
      warn "ambiguous amount of #{@file_extension} files in #{folder}" if files.length > 1
      warn "no #{@file_extension} files in #{folder}" if files.length < 1
      return files[0]
    end
    logs "NO FOLDER get_project_folder(name = #{name}, dir = #{dir}, year = #{year})"
    return false
  end


  ##
  # Path to project folder
  # If the folder exists
  # dir can be :working or :archive 
  #
  # TODO untested for archives
  def get_project_folder( name, dir=:working, year=Date.today.year )
    name = AsciiSanitizer.process    name
    name = AsciiSanitizer.clean_path name
    year = year.to_s
    target = File.join @dirs[dir], name       if dir == :working
    target = File.join @dirs[dir], year, name if dir == :archive
    return target if File.exists? target
    false
  end

  ##
  # list projects
  # lists project files
  def list_project_names(dir = :working, year=Date.today.year)
    return unless check_dir(dir)
    if dir == :working
      paths = Dir.glob File.join @dirs[dir], "/*"
      names = paths.map {|path| File.basename path }
    elsif dir == :archive
      paths = Dir.glob File.join @dirs[dir], year.to_s, "/*"
      names = paths.map {|path|
        file_path = get_project_file_path (File.basename path), :archive, year
        name = File.basename file_path, @file_extension
      }
      return names
    else
      error "unknown path #{dir}"
    end
  end

  ##
  # list projects
  # lists project files
  # (names actually contains paths)
  def list_projects(dir = :working, year=Date.today.year)
    return unless check_dir(dir)
    if dir == :working
      folders = Dir.glob File.join @dirs[dir], "/*"
      paths = folders.map {|path| get_project_file_path File.basename path }
    elsif dir == :archive
      folders = Dir.glob File.join @dirs[dir], year.to_s, "/*"
      paths = folders.map {|path| get_project_file_path (File.basename path), :archive, year }
    else
      error "unknown path #{dir}"
    end

    puts "WARNING! one folder is not correct" if paths.include? false
    paths.keep_if{|v| v}
  end

  ##
  # list projects
  # lists project files
  # (names actually contains paths)
  def list_projects_all
    names = []

    #first all archived projects, ever :D
    archives = Dir.glob File.join @dirs[:archive], "/*"
    archives.sort!
    archives.each do |a|
      paths = Dir.glob File.join a, "/*"
      year = File.basename a
      names += paths.map { |path|
        get_project_file_path (File.basename path), :archive, year
      }
    end

    #then all working projects
    names += list_projects :working

    return names
  end

  ##
  #  Move to archive directory
  #  @name 
  ## ProjectsPlumber.archive_project should use AsciiSanitizer
  def archive_project(project, year = nil, prefix = '')
    project = open_project project
    return false unless project.class == @project_class
    
    year ||= project.date.year
    year_folder = File.join @dirs[:archive], year.to_s
    FileUtils.mkdir year_folder unless File.exists? year_folder

    project_folder = get_project_folder project.name, :working
    if prefix and prefix.length > 0
      archived_name = project.name.prepend(prefix + "_")
      target = File.join year_folder, archived_name
    else
      target = File.join year_folder, project.name
    end

    return false unless project_folder
    return false if list_project_names(:archive, year).include? project.name

    logs "moving: #{project_folder} to #{target}" if target and project_folder

    FileUtils.mv project_folder, target
    if check_git()
      git_update_path project_folder
      git_update_path target
    end
    return target
  end

  ##
  #  Move to archive directory
  def unarchive_project(project, year = Date.today.year)
    project = open_project project
    return false unless project.class == @project_class

    name         = project.name
    path         = project.data :project_path
    cleaned_name = File.basename(path,@file_extension)
    source       = get_project_folder name, :archive, year
    target       = File.join @dirs[:working], cleaned_name

    logs "moving #{source} to #{target}"
    return false unless source

    unless get_project_folder cleaned_name
      FileUtils.mv source, target
      if check_git()
        git_update_path source
        git_update_path target
      end
      return true
    else
      return false
    end
  end

end
