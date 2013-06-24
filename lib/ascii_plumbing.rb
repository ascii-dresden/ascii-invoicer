class ProjectsPlumber

  attr_reader :projects, :dirs, :files

  def initialize(options)
    @working_dir  = options.working_dir
    @template_yml = options.template_yml
    #puts "hey there!"
    error "projects folder fail" unless check_projects_folder()
   
    # read all the projects
    list_projects()
  end
  
  ## Checks the existens and creates folder if neccessarry
  def check_projects_folder
    if File.exists? "#{@working_dir}"
      return true
    else
      FileUtils.mkdir "#{@working_dir}"
      puts "Created Projects Directory"
      return false
    end
  end

  def check_project name
    get_project_file name
    return true if not @project_file.nil? and File.exists?(@project_file) 
    if File.exists?(get_project_file name)
      return true
    else
      return false
    end
  end

  def get_project_folder name 
    "#{@working_dir}#{name}/"
  end

  def get_project_file_path name
    "#{get_project_folder name}/#{name}.yml"
  end

  ## path to project file
  def get_project_file name
    if @project_file.nil?
      files = Dir.glob("#{get_project_folder name}*.yml")
      fail "ambiguous amount of yml files in #{name}" if files.length != 1
      return files[0]
    else
      @project_file
    end
  end

  ## list projects
  def parse_projects
    check_projects_folder
    dirs = Dir.entries(@working_dir).delete_if { |v| v[0] == '.' }
    @projects = []
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
    @dirs = []
    @files = {}
    @projects.each { |invoice|
      @dirs.push invoice['name']
      @files[invoice['name']] = get_project_file  invoice['name']
    }
    @dirs
  end

  ### Project life cycle
  ## creates new project folder and file
  def new_project(name)
    check_projects_folder

    unless File.exists? "#{@working_dir}/#{name}"
      FileUtils.mkdir "#{@working_dir}/#{name}"
      puts "Created Project Folder #{get_project_folder name}"
    end

    unless File.exists? get_project_file_path name
      FileUtils.cp @template_yml, get_project_file_path(name)
      puts "Created Empty Project #{get_project_file_path name}"
    else
      puts "Project File exists.#{get_project_file name}"
      if confirm "Do you want to overwrite it?"
        FileUtils.cp @template_yml, get_project_file(name)
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
    FileUtils.mkdir @done_dir unless(File.exists? @done_dir)
    FileUtils.mkdir "#{@done_dir}/#{year}" unless(File.exists? @done_dir)
    FileUtils.mv "#{@working_dir}#{name}", "#{@done_dir}R#{rn}-#{year}-#{name}" if check_project name
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
