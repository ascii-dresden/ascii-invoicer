class ProjectsPlumber

  attr_reader :archived_projects, :working_projects, :dirs, :s
  attr_writer :options

  def initialize(options)
    @options = options
    #puts "hey there!"
    error "projects folder fail" unless check_projects_folder()
   
    # read all the projects
    if @options.read_archive
      list_projects @options.done_dir
    else
      list_projects @options.working_dir
    end
  end

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
    get_project_file name
    return true if not @options.project_file.nil? and File.exists?(@options.project_file) 
    if File.exists?(get_project_file name)
      return true
    else
      return false
    end
  end

  def get_project_folder name 
    if @options.project_file.nil?
    "#{@options.working_dir}#{name}/"
    else
      # means the file was not taken from the repository buy addressed directly with -f 
      "./"
    end
  end

  #do not use this for opening the file, only for making up a name for new files
  def get_project_file_path name
    "#{get_project_folder name}/#{name}.yml"
  end

  ## path to project file
  def get_project_file name
    if @options.project_file.nil?
      unless name.nil?
      files = Dir.glob("#{get_project_folder name}*.yml")
      fail "ambiguous amount of yml files in \"#{name}\"" if files.length != 1
      return files[0]
      else
        fail "name not given"
      end
    else
      @options.project_file
    end
  end

  ## list projects
  def list_projects folder
    check_projects_folder()
    pp folder
    @dirs = Dir.entries(folder ).delete_if { |v| v[0] == '.' }
    @files = {}
    @working_projects = []

    @dirs.each_index do |i|
      invoice  = open_project get_project_file dirs[i]
      invoice['name'] = dirs[i]
      invoice['rnumber'] =  !invoice['rnumber'].nil? ? invoice['rnumber'] : "_"
      @working_projects.push invoice
      @files[invoice['name']] = get_project_file  invoice['name']
      #puts "#{i+1} #{projects[i].ljust 25} #{invoice['signature'].ljust 17} R#{invoice['rnumber'].to_s.ljust 3} #{invoice['date']}"
    end
    @working_projects.sort_by! { |invoice| invoice['raw_date'] }
    return
  end

  ### Project life cycle
  ## creates new project folder and file
  def new_project(name)
    check_projects_folder

    unless File.exists? "#{@options.working_dir}/#{name}"
      FileUtils.mkdir "#{@options.working_dir}/#{name}"
      puts "Created Project Folder #{get_project_folder name}"
    end

    unless File.exists? get_project_file_path name
      FileUtils.cp @options.template_yml, get_project_file_path(name)
      puts "Created Empty Project #{get_project_file_path name}"
    else
      puts "Project File exists.#{get_project_file name}"
      if confirm "Do you want to overwrite it?"
        FileUtils.cp @options.template_yml, get_project_file(name)
      end
    end

  end

  ## Move to archive directory
  def archive_project name
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
