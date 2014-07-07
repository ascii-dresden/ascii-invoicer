# encoding: utf-8
require 'fileutils'
LIBPATH = File.split(__FILE__)[0]
require "#{LIBPATH}/gitplumber.rb"


class ProjectsPlumber

  attr_reader :dirs
  include GitPlumber

  def initialize(settings)
    @settings = settings
    @dirs = {}

    @dirs[:template] = File.join @settings['script_path'], @settings['templates']['project']
    @dirs[:storage]  = File.join @settings['path'], @settings['dirs']['storage']
    @dirs[:working]  = File.join @dirs[:storage], @settings['dirs']['working']
    @dirs[:archive]  = File.join @dirs[:storage], @settings['dirs']['archive']
  end

  ##
  # *wrapper* for puts()
  # depends on @settings.silent = true|false

  def logs message, force = false
    puts "#{__FILE__}:\n\t#{message}" if @settings['verbose'] or force
  end

  ##
  # Checks the existens of one of the three basic dirs.
  # dir can be either :storage, :working or :archive
  # and also :template
  def check_dir(dir)
    return true if File.exists? "#{@dirs[dir]}"
    false
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

  ### DEPRECATED
  ## creates new project_dir and project_file
  ## returns path to project_file
  #def new_project(_name)
  #  name = _name.strip()
  #  name.sub!(/^\./,'') # removes hidden_file_dot '.' from the begging
  #  name.gsub!(/\//,'_') 
  #  name.gsub!(/\//,'_') 

  #  # copy template_file to project_dir
  #  folder = _new_project_folder(name)
  #  if folder
  #    target = File.join folder, name+@settings['project_file_extension']

  #    FileUtils.cp @dirs[:template], target
  #    logs "#{folder} created"
  #    return target
  #  else
  #    return false
  #  end
  #end

  ##
  # creates new project_dir and project_file
  # returns path to project_file
  def new_project_fill(_name)
    name = _name.strip()
    name.sub!(/^\./,'') # removes hidden_file_dot '.' from the begging
    name.gsub!(/\//,'_') 
    name.gsub!(/\//,'_') 

    event_name     = name
    personal_notes = @settings['personal_notes']
    manager_name   = @settings["manager_name"]
    default_lang   = @settings["default_lang"]
    default_tax    = @settings["default_tax"]
    #automatically_iterated_invoice_number = ""

    filename = @dirs[:template]

    ## Approach A ( Thomas Kühn )
    engine=ERB.new(File.read(filename),nil,'<>')
    result = engine.result(binding)

    # copy template_file to project_dir
    folder = _new_project_folder(name)
    if folder
      target = File.join folder, name+@settings['project_file_extension']

      puts "writing into #{target}"
      file = File.new target, "w"
      result.lines.each do |line|
        file.write line
      end
      file.close

      logs "#{folder} created"
      return target
    else
      return false
    end
  end



  ##
  # path to project file
  # there may only be one @settings['project_file_extension'] file per project folder
  #
  # untested
  def get_project_file_path(name, dir=:working, year=Date.today.year)
    folder = get_project_folder(name, dir, year)
    if folder
      files = Dir.glob File.join folder, "*#{@settings['project_file_extension']}"
      fail "ambiguous amount of #{@settings['project_file_extension']} files (#{name})" if files.length != 1
      return files[0]
    end
    return false
  end


  ##
  # Path to project folder
  # If the folder exists
  # dir can be :working or :archive 
  #
  # TODO untested for archives
  def get_project_folder( name, dir=:working, year=Date.today.year )
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
        name = File.basename file_path, @settings['project_file_extension']
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
      paths = Dir.glob File.join @dirs[dir], "/*"
      names = paths.map {|path| get_project_file_path File.basename path }
    elsif dir == :archive
      paths = Dir.glob File.join @dirs[dir], year.to_s, "/*"
      names = paths.map {|path| get_project_file_path (File.basename path), :archive, year }
    else
      error "unknown path #{dir}"
    end
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
  def archive_project(name, year = Date.today.year, prefix = '')
    name.strip!
    name.sub!(/^\./,'') # removes hidden_file_dot '.' from the begging
    name.gsub!(/\//,'_') 
    name.gsub!(/\//,'_') 
    year_folder = File.join @dirs[:archive], year.to_s
    FileUtils.mkdir year_folder unless File.exists? year_folder

    project_folder = get_project_folder name, :working
    if prefix and prefix.length > 0
      target = File.join year_folder, name.prepend(prefix + "_")
    else
      target = File.join year_folder, name
    end

    return false unless project_folder
    return false if list_project_names(:archive, year).include? name

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
  def unarchive_project(name, year = Date.today.year)
    name.strip!

    path = get_project_file_path(name, :archive, year)
    cleaned_name = File.basename(path,@settings['project_file_extension'])

    source = get_project_folder name, :archive, year

    target = File.join @dirs[:working], cleaned_name

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

class String
  def last
    self.scan(/.$/)[0]
  end
  def deprefix(prefix)
    self.partition(prefix)[2]
  end
end
