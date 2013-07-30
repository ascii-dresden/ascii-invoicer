# encoding: utf-8
module AsciiInvoiceProject
  ## Use Option parser or leave it if only one argument is given

  def project_list_by_date(paths)
    projects = []
    paths.each do |path|
      project = InvoiceProject.new $SETTINGS
      project.open path
      project.validate :display
      projects.push project
    end
    projects.sort_by! { |project| project.data[:date] }
    return projects
  end

  def print_project_list(paths, options = {})
    projects = project_list_by_date paths

    if options[:csv] 
      print_project_list_csv projects
    elsif options[:yaml] 
      print_project_list_yaml projects
    else
      print_project_list_plain projects
    end
  end

  def print_project_list_plain(projects)
    projects.each_index do |i|
      project   = projects[i]

      number    = (i+1).to_s
      number    = number.rjust 4
      name      = project.data[:name].ljust 34
      signature = project.data[:manager].ljust 20
      rnumber   = ""#project.data[:numbers]['invoice_short'].to_s.ljust 4
      date      = project.data[:date].strftime("%d.%m.%Y").rjust 15
      #errors = project.data[:valid]? "": Paint[" ✗",:red]+"(#{project.errors).join(', ')})"
      errors    = project.errors

      line = "#{number}. #{name} #{signature} #{rnumber} #{date} #{errors}"
      puts line
    end
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_yaml(projects)
    projects.each do |p|
      puts p.to_yaml
      puts "...\n\n"
  end
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_csv(projects)
    header = [
      'date', 'invoice_long', 'invoice_short', 'offer', 'event', 'name', 'caterer', 'time', 'invoiced sum',
    ]
    puts header.to_csv
    projects.each do |p|
      line = [
        p['date'],
        p['numbers']['invoice_long'],
        p['numbers']['invoice_short'],
        p['numbers']['offer'],
        p['event'],
        p['name'],
        p['caterer'],
        p['hours']['time'].to_s + 'h',
        p['sums'],
      ]
      puts line.to_csv
    end
  end

  def pick_project(index)
    plumber = ProjectsPlumber.new $SETTINGS
    if options[:archives]
      paths = plumber.list_projects :archive, options[:archives]
    else
      paths = plumber.list_projects
    end
    iindex = index.to_i - 1
    if iindex > -1
      projects = project_list_by_date(paths)
      if iindex <= projects.length - 1
        return projects[iindex]['path']

      else error "Invalid index!"
      end

    else
      projects = @plumber.list_project_names
      if projects.include? index
        return @plumber.get_project_file_path index

      else error "Invalid name!"
      end
    end
  end

  
  ## hand path to editor
  def edit_file(path)
    logs "Opening #{path} in #{$SETTINGS['editor']}"
    pid = spawn "#{$SETTINGS['editor']} #{path}"
    Process.wait pid
    project = InvoiceProject.new $SETTINGS
    project.open path
    project.validate()
    error "WARNING: the file you just edited contains errors! (#{project.data['parse_errors']})" unless project.data['valid']
    unless no? "would you like to edit it again? [y|N]"
      edit_file path
    end

  end

  def logs message, force = false
    puts "#{__FILE__}: #{message}" if $SETTINGS['verbose'] or force
  end

  ## creates a  latex file from NAME of the desired TYPE
  def write_tex(name, type)
    return false unless @plumber.check_project name
    path    = @plumber.get_project_file name
    pfolder = @plumber.get_project_folder name

    project = InvoiceProject.new
    project.load_templates :project => @options.template_invoice , :offer => @options.template_offer
    project.read_file path

    project.type = type
    project.project_name = name
    if name.nil? or name.size == 0 
      if project.dump['event'].nil? or project.dump['event'].size == 0
        name = path.tr '/', '_'
        puts name
      else
        name = project.dump['event']
        puts "name taken from event \"#{name}\""
      end
    end

    if project.is_valid or true
      tex = project.create

      d = project.dump

      # datei namen
      case type
      when :project
        datestr = d['raw_date'].strftime("%Y-%m-%d")
        filename = "R#{d['rnumber'].to_s.rjust 3, "0"} #{name} #{datestr}.tex"
        file = "#{pfolder}"+filename
      when :offer
        #datestr = d['raw_date'].strftime("%y%m%d") # date of project
        datestr = Date.today.strftime("%y%m%d") # current date
        filename = "#{datestr} Angebot #{name}.tex"
        file = "#{pfolder}"+filename
      end

      pp file
      f = File.new file, "w"

      tex.each do |line|
        f.write line
      end
      f.close
      puts "file writen: #{file}"
      file

      puts "Rendering #{file} with #{@options.latex}"
      silencer = @options.verbose ? "" : "> /dev/null" 
      system "#{@options.latex} \"#{file}\" -output-directory . #{silencer}" #TODO output directory is not generic
      unless @options.keep_log
        FileUtils.rm filename.gsub('.tex','.log')
        FileUtils.rm filename.gsub('.tex','.aux')
      end
    else
      puts "project is not valid"
    end
  end
end
