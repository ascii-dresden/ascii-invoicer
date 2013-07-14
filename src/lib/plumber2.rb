class ProjectsPlumber

  attr_reader :dirs

  def initialize(settings)

    # expecting to find here
    #   @settings.storage_dir
    #   @settings.working_dir
    #   @settings.archive_dir
    @settings = settings
    @dirs = {}
    @dirs[:storage] =           @settings.storage_dir
    @dirs[:working] = File.join @settings.storage_dir, @settings.working_dir
    @dirs[:archive] = File.join @settings.storage_dir, @settings.archive_dir       

  end

  def logs message
    puts "    -- PLUMBER -- : #{message}"

  end

  ## Checks the existens and creates folder if neccessarry
  # dir can be either :storage, :working or :archive
  def check_dir(dir)
    if File.exists? "#{@dirs[dir]}"
      return true
    else
      return false
    end
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
 
  def check_and_create
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

  ### Project life cycle
  ## creates new project folder and file
  def new_project(name)
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
