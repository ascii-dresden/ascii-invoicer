# encoding: utf-8

@options                  = OpenStruct.new
@options.projectname      = nil # leave this way !!
@options.operations       = [] # :invoice, :offer, :edit, :new
@options.test             = false
@options.path             = './'
@options.editor           = 'vim'
@options.latex            = 'pdflatex'
@options.working_dir      = "#{@options.path}caterings/open/"
@options.done_dir         = "#{@options.path}caterings/done/"
@options.template_dir     = "#{@options.path}templates/"
@options.template_yml     = "#{@options.template_dir}vorlage.yaml"
@options.template_invoice = "#{@options.path}latex/ascii-rechnung.tex"
@options.template_offer   = "#{@options.path}latex/ascii-angebot.tex"
@options.keep_log         = false
@options.verbose          = false


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

  # close a project
  opts.on( '--close NAME', 'Close project ' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :close
  end

  opts.on( '-d', '--dump [NAME]', 'Create offer from project' ) do |name|
    @options.projectname = @options.projectname.nil? ? name : @options.projectname
    @options.operations.push :dump
    #write_tex project, :offer unless project.nil?
  end

  opts.on( '--file NAME', 'Manualy specify .yml file (not implemented)' ) do |name|
    puts "--file is not yet implemented -- sorry"
    exit
  end

  opts.on('-c', '--check', "Show Debug information") do
    debug_info()
    exit
  end

  opts.on_tail( '-h', '--help', 'Display this screen' ) do
    puts opts
    @options.operations.push :help
    exit
  end
end
