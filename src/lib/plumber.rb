class Old_ProjectsPlumber


  attr_reader :archived_projects, :working_projects, :dirs, :ordered_dirs
  attr_writer :settings

  def initialize(settings)

    # expecting to find here
    #   @settings.storage_dir
    #   @settings.working_dir
    #   @settings.archive_dir
    @settings = settings
    @dirs = {}
    @dirs[:working] = @settings.working_dir
    @dirs[:archive] = @settings.archive_dir
    @dirs[:storage] = @settings.storage_dir

    ## read all the projects
    #if @settings.read_archive
    #  list_archives()
    #else
    #  @current_dir = @settings.working_dir
    #  list_projects @current_dir
    #end
  end

  ## Checks the existens and creates folder if neccessarry
  def check_projects_folder(dir = :working)
    if File.exists? "#{@dirs[dir]}"
      return true
    else
      FileUtils.mkdir "#{@dirs[dir]}"
      puts "Created \"#{dir.to_s}\" Directory"
      return false
    end
  end

  ## If the folder exists and if there is a yml
  def check_project name
    get_project_file name
    return true if not @settings.project_file.nil? and File.exists?(@settings.project_file) 

    if File.exists?(get_project_file name)
      return true
    else
      return false
    end
  end




  ## open project file from name
  def pick_project input, dir = :working
    if (number = input.to_i) != 0
      error "invalid index" if number > @dirs.size
      projectname = @ordered_dirs[number-1]
    else
      projectname = input
    end
    return projectname
  end





  def get_project_folder name 
    if @settings.project_file.nil?
    "#{@current_dir}#{name}/"
    else
      # means the file was not taken from the repository buy addressed directly with -f 
      "./"
    end
  end




  #do not use this for opening the file, only for making up a name for new files
  def get_project_file_path name
    "#{get_project_folder name}#{name}.yml"
  end




  ## path to project file
  def get_project_file name
    if @settings.project_file.nil?
      unless name.nil?
      files = Dir.glob("#{get_project_folder name}*.yml")
      fail "ambiguous amount of yml files in \"#{name}\"" if files.length != 1
      return files[0]
      else
        fail "name not given"
      end
    else
      @settings.project_file
    end
  end





  
  def list_archives
    year_dirs = Dir.entries(@settings.archive_dir).delete_if { |v| v[0] == '.' }
    unless year_dirs.include?(@settings.archive_year)
      error "no such year \"#{@settings.archive_year}\" in archive"
    end
    @current_dir = "#{@settings.archive_dir}#{@settings.archive_year}/"
    puts @current_dir
    list_projects @current_dir
  end



  ## list projects
  def list_projects folder
    check_projects_folder()
    @dirs = Dir.entries(folder).delete_if { |v| v[0] == '.' }
    @files = {}
    @working_projects = []
    @ordered_dirs = []

    @dirs.each_index do |i|
      invoice  = open_project get_project_file dirs[i]
      invoice['name'] = dirs[i]
      invoice['rnumber'] =  !invoice['rnumber'].nil? ? invoice['rnumber'] : "_"
      @working_projects.push invoice
      @files[invoice['name']] = get_project_file  invoice['name']
      #puts "#{i+1} #{projects[i].ljust 25} #{invoice['signature'].ljust 17} R#{invoice['rnumber'].to_s.ljust 3} #{invoice['date']}"
    end
    @working_projects.sort_by! { |invoice| invoice['raw_date'] }
    @working_projects.each do |invoice|
      @ordered_dirs.push invoice['name']
    end
    return
  end

  ### Project life cycle
  ## creates new project folder and file
  def new_project(name)
    check_projects_folder()

    unless File.exists? "#{@settings.working_dir}/#{name}"
      FileUtils.mkdir "#{@settings.working_dir}/#{name}"
      puts "Created Project Folder #{get_project_folder name}"
    end

    unless File.exists? get_project_file_path name
      FileUtils.cp @settings.template_yml, get_project_file_path(name)
      file_path = get_project_file_path name
      puts "Created Empty Project #{file_path}"
    else
      puts "Project File exists.#{get_project_file name}"
      if sure? "Do you want to overwrite it?"
        FileUtils.cp @settings.template_yml, get_project_file(name)
      end
    end
    return file_path
  end

  ## Move to archive directory
  def archive_project name
    # TODO rename folders
    invoice = open_project get_project_file name
    rn  =  !invoice['rnumber'].nil? ? invoice['rnumber'] : "_"
    year = invoice['raw_date'].year

    archive_dir = @settings.archive_dir
    archive_year_dir = "#{archive_dir}#{year}/"

    FileUtils.mkdir archive_dir unless(File.exists? archive_dir)
    FileUtils.mkdir archive_year_dir unless(File.exists? archive_year_dir)
    FileUtils.mv "#{@settings.working_dir}#{name}", "#{archive_year_dir}R#{rn.to_s.rjust(3,'0')}-#{year}-#{name}" if check_project name
    puts "#{archive_year_dir}R#{rn.to_s.rjust(3,'0')}-#{year}-#{name}"
    puts "archived #{name} \"#{invoice['event']}\""
  end

  ## Move to archive directory
  def unarchive_project name
    #invoice = open_project get_project_file name
    file     = get_project_file name
    folder   = get_project_folder name

    project_name = file.split('/').last.split('.').first

    puts project_name
    destination = "#{@settings.working_dir}#{project_name}"

    puts()
    FileUtils.mv folder, destination
    puts "moved #{folder} to #{destination}"

  end



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




end
