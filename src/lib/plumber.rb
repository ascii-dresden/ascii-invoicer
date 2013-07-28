require 'fileutils'


class ProjectsPlumber

  attr_reader :dirs

  def initialize(settings)

    # expecting to find in settings
    #   @settings.path
    #   @settings.storage_dir
    #   @settings.working_dir
    #   @settings.archive_dir
    #   @settings.template_file
    #   @settings.silent = false
    #   @project_suffix = '.yml'

    @settings = settings
    @dirs = {}
    @dirs[:storage] = File.join @settings['path'], @settings['dirs']['storage']
    @dirs[:working] = File.join @dirs[:storage], @settings['dirs']['working']
    @dirs[:archive] = File.join @dirs[:storage], @settings['dirs']['archive']

    @project_suffix = @settings['project_suffix']
    @project_suffix = '.yml' if @project_suffix.nil?

    @template_path  = File.join @settings['path'], @settings['templates']['project']
    @dirs[:template] = @template_path

  end

  ##
  # *wrapper* for puts()
  # depends on @settings.silent = true|false

  def logs message, force = false
    puts "#{__FILE__}: #{message}" if @settings['verbose'] or force
  end

  ##
  # Checks the existens of one of the three basic dirs.
  # dir can be either :storage, :working or :archive
  def check_dir(dir)
    return true if File.exists? "#{@dirs[dir]}"
    false
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
  # returns path to project_file
  def new_project(_name)
    name = _name.strip()
    name.sub!(/^\./,'') # removes hidden_file_dot '.' from the begging
    name.gsub!(/\//,'_') 
    name.gsub!(/\//,'_') 

    # copy template_file to project_dir
    folder = _new_project_folder(name)
    if folder
      target = File.join folder, name+@project_suffix

      FileUtils.cp @dirs[:template], target
      logs "#{folder} created"
      return target
    else
      return false
    end
  end



  ##
  # path to project file
  # there may only be one @project_suffix file per project folder
  #
  # untested
  def get_project_file_path(name, dir=:working, year=Date.today.year)
    folder = get_project_folder(name, dir, year)
    if folder
      files = Dir.glob File.join folder, "*#{@project_suffix}"
      fail "ambiguous amount of #{@project_suffix} files (#{name})" if files.length != 1
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
    target = File.join @dirs[dir], name if dir == :working
    target = File.join @dirs[dir], year, name if dir == :archive
    return target if File.exists? target
    false
  end

  






  ##
  # turn index or name into path
  #
  # untested
  def pick_project input, dir = :working
  end



  ##
  # list projects
  def list_projects(dir = :working)
    return unless check_dir(dir)
    #TODO FIXME XXX
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
    target = File.join year_folder, name.prepend(prefix)

    return false unless project_folder

    logs "moving: #{project_folder} to #{target}" if target and project_folder
    FileUtils.mv project_folder, target
    return target
  end

  ##
  #  Move to archive directory
  def unarchive_project(name, year = Date.today.year)
    name.strip!

    path = get_project_file_path(name, :archive, year)
    cleaned_name = File.basename(path,@project_suffix)

    source = get_project_folder name, :archive, year

    target = File.join @dirs[:working], cleaned_name

    logs "moving #{source} to #{target}"
    return false unless source

    unless get_project_folder cleaned_name
      FileUtils.mv source, target
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
