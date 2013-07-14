class ProjectsPlumber

  attr_reader :dirs

  def initialize(settings)

    # expecting to find here
    #   @settings.path
    #   @settings.storage_dir
    #   @settings.working_dir
    #   @settings.archive_dir
    #   @settings.template_file

    @settings = settings
    @dirs = {}
    @dirs[:storage] = File.join @settings.path, @settings.storage_dir
    @dirs[:working] = File.join @dirs[:storage], @settings.working_dir
    @dirs[:archive] = File.join @dirs[:storage], @settings.archive_dir       

  end

  # wrapper for puts:w

  def logs message
    puts "       #{__FILE__} : #{message}"
  end

  # dir can be either :storage, :working or :archive
  def check_dir(dir)
    return true if File.exists? "#{@dirs[dir]}"
    false
  end

  # create a dir
  # dir can be either :storage, :working or :archive
  def create_dir(dir)
    unless check_dir(dir)
      if dir == :storage or check_dir :storage
        FileUtils.mkdir "#{@dirs[dir]}"
        logs "Created \"#{dir.to_s}\" Directory (#{@dirs[dir]})"
        return true
      end
    end
    false
  end
  ## If the folder exists and if there is a yml
 
  ### Project life cycle

  ##
  # creates new project_dir and project_file
  #
  # returns path to project_file
  def new_project(name)
    unless check_dir :working
      logs "missing working directory!"
      return false
    end
    # - check of existing project with the same name
    # - create project_dir storage_dir/working_dir/name
    # - copy template_file to project_dir
    # - return path to project file
  end



  def check_project name
  end




  ## open project file from name
  def pick_project input, dir = :working
  end





  def get_project_folder name 
  end




  #do not use this for opening the file, only for making up a name for new files
  def get_project_file_path name
    "#{get_project_folder name}#{name}.yml"
  end




  ## path to project file
  def get_project_file name
  end





  
  def list_archives
  end



  ## list projects
  def list_projects folder
  end

  ## Move to archive directory
  def archive_project name
  end

  ## Move to archive directory
  def unarchive_project name
  end

  def open_project file # or folder ??
  end


end
