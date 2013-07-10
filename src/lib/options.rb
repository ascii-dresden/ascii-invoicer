# encoding: utf-8
@version = '1.3.0'

@options                  = OpenStruct.new
@options.projectname      = nil # leave this way !!
@options.operations       = [] # :invoice, :offer, :edit, :new
@options.test             = false
@options.path             = './'
@options.script_path      = $SCRIPT_PATH + '/'
@options.editor           = 'vim'
@options.latex            = 'pdflatex'
@options.store_dir        = "#{@options.path}caterings/"
@options.working_dir      = "#{@options.store_dir}open/"
@options.done_dir         = "#{@options.store_dir}done/"
@options.template_dir     = "#{@options.script_path}templates/"
@options.template_yml     = "#{@options.template_dir}vorlage.yaml"
@options.template_invoice = "#{@options.script_path}latex/ascii-rechnung.tex"
@options.template_offer   = "#{@options.script_path}latex/ascii-angebot.tex"
@options.read_archive     = false # overwritten if "--archive" is used
@options.archive_year     = Date.today.year.to_s # overwritten if "--archive" is used
@options.keep_log         = false
@options.verbose          = false

def read_file(datafile)
  if File.exists?(datafile)
    file = File.open(datafile)
    begin
    data = YAML::load(file)
    rescue
      error " error reading #{file}"
    end
    return data
  end
end


@settings = read_file "#{$SCRIPT_PATH}/lib/settings.yml"


## OptionsParser
@optparse = OptionParser.new do|opts|
  opts.banner = "Usage: ascii.rb [name|number] or ascii.rb [options]
    (note that you can always only handle one project)"

  # keep log
  opts.on_tail( '-k', '--keep-log', 'Do not delete latex log and aux files' ) do |name|
    @options.keep_log = true
  end

  # verbose
  opts.on_tail( '-v', '--verbose', 'Be verbose' ) do |name|
    @options.verbose = true
  end

  opts.on_tail( '-V', '--veryverbose', 'Be very verbose' ) do |name|
    @options.verbose = true
    @options.veryverbose = true
  end

  # choose project 
  opts.on( '-p', '--project NAME', 'Use this project (overrides others)' ) do |name|
    @options.projectname = name
  end

  # new project
  opts.on( '-n', '--new NAME', 'Create new Project' ) do |name|
    #new_project @options.projectname = name
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :new
  end

  # edit
  opts.on('-e', '--edit [NAME]', "Edit Project") do |name|
    #open_project @options.projectname = name
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :edit
  end

  # create invoice
  opts.on( '-i', '--invoice [NAME]', 'Create invoice from project' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :invoice
    #write_tex project, :invoice unless project.nil?
  end

  # create offer
  opts.on( '-o', '--offer [NAME]', 'Create offer from project' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :offer
    #write_tex project, :offer unless project.nil?
  end

  # list projects
  opts.on( '-l', '--list', 'List all projects' ) do |name|
    #print_project_list
    @options.operations.push :list
  end

  opts.on( '-s', '--sum [NAME]', 'Sum up project sum' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :sum
    #write_tex project, :offer unless project.nil?
  end

  opts.on( '-d', '--dump [NAME]', 'Dump raw project data' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :dump
    #write_tex project, :offer unless project.nil?
  end

  opts.on( '-f','--file PATH', 'Manualy specify .yml file' ) do |path|
    @options.project_file = path
  end

  opts.on_tail( '-h', '--help', 'Display this screen' ) do
    puts opts
    @options.operations.push :help
    exit
  end

  # close a project
  opts.on( '--close NAME', 'Close project ' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :archive
  end

  # close a project
  opts.on( '--reopen NAME', 'Move closed project back to working dir (Combine with -a)' ) do |name|
    @options.read_archive = true
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :unarchive
  end

  # list projects
  opts.on( '-a', '--archive [year]', 'List archived projects (default is current year)' ) do |year|
    #print_project_list
    @options.archive_year = year unless year.nil? or year.length == 0
    @options.read_archive = true
  end

  ## reopen a project
  #opts.on( '--reopen NAME', 'Reopen a closed project ' ) do |name|
  #  exit
  #  @options.projectname = @options.projectname.nil? ? name : @options.projectname
  #  @options.operations.push :close
  #end

end

@optparse.version = @version
