# encoding: utf-8

@options                  = OpenStruct.new
@options.projectname      = nil # leave this way !!
@options.test             = false
@options.path             = './'
@options.editor           = 'vim'
@options.latex            = 'pdflatex'
@options.working_dir      = "#{@options.path}projects/"
@options.template_dir     = "#{@options.path}templates/"
@options.template_yml     = "#{@options.template_dir}vorlage.yaml"
@options.template_invoice = "latex/ascii-rechnung.tex"
@options.template_offer   = "latex/ascii-angebot.tex"
@options.keep_log         = false
@options.verbose          = false


## OptionsParser
@optparse = OptionParser.new do|opts|

  opts.banner = "Usage: ascii.rb [name|number] or ascii.rb [options]"

  opts.on_tail( '-v', '--verbose', 'Be verbose' ) do |name|
    @options.verbose = true
  end

  opts.on( '-p', '--project NAME', 'Use this project' ) do |name|
    @options.projectname = name
  end

  opts.on( '-n', '--new NAME', 'Create new Project' ) do |name|
    new_project @options.projectname = name
  end

  opts.on('-e', '--edit [NAME]', "Edit Project") do |name|
    open_project @options.projectname = name
  end

  opts.on( '-i', '--invoice [NAME]', 'Create invoice from project' ) do |name|
    project = @options.projectname.nil? ? name : @options.projectname
    write_tex project, :invoice unless project.nil?
  end

  opts.on( '-o', '--offer [NAME', 'Create offer from project' ) do |name|
    project = @options.projectname.nil? ? name : @options.projectname
    write_tex project, :offer unless project.nil?
  end

  opts.on( '-l', '--list', 'List all projects (not implemented)' ) do |name|
    print_project_list
    exit
  end

  opts.on( '--close NAME', 'Close project (no implemented)' ) do |name|
    puts "--close not yet implemented -- sorry"
    exit
  end

  opts.on( '--clean NAME', 'Removes everything but the project file (not implemented)' ) do |name|
    puts name
    exit
  end

  opts.on('-c', '--check', "Show Debug information") do
    debug_info()
    exit
  end

  opts.on_tail( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
