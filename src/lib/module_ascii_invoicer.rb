# encoding: utf-8
module AsciiInvoicer
  ## Use Option parser or leave it if only one argument is given

  def open_projects(paths, validation = :list, sort = :date)
    projects = []
    paths.each do |path|
      project = InvoiceProject.new $SETTINGS
      project.open path
      project.validate validation
      projects.push project
    end
    projects.sort_by! { |project| project.data[sort] }
    return projects
  end

  def print_project_list_plain(projects)
    table = CliTable.new
    table.borders = false
    projects.each_index do |i|
      p  = projects[i]
      table.add_row [
        (i+1).to_s+".", 
        p.data[:name].ljust(35), 
        p.data[:manager], 
        p.data[:invoice_number], 
        p.data[:date].strftime("%d.%m.%Y"), 
      ]
    end
    table.column_alignments = [:r, :l, :l]
    puts table.build
  end

  def print_project_list_verbose(projects)
    table = CliTable.new
    table.borders = false
    projects.each_index do |i|
      p  = projects[i]
      table.add_row [
        (i+1).to_s+".",
        p.data[:event] ? p.data[:event] : "",
        p.data[:name],
        p.data[:manager],
        p.data[:invoice_number],
        p.data[:date].strftime("%d.%m.%Y"),
        p.data[:valid].to_s,
      ]
    end
    table.set_alignment(0, :r)
    table.set_alignment(5, :r)
    puts table
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_yaml(projects)
    projects.each do |p|
      puts p.data.to_yaml
      puts "...\n\n"
    end
  end

  def costbox project 
    data = project.data

    ci   = data[:costs_invoice ].to_s.rjust(7)
    co   = data[:costs_offer   ].to_s.rjust(7)

    ti   = data[:taxes_invoice ].to_s.rjust(7)
    to   = data[:taxes_offer   ].to_s.rjust(7)

    fi   = data[:final_invoice ].to_s.rjust(7)
    fo   = data[:final_offer   ].to_s.rjust(7)

    toto = data[:total_offer   ].to_s.rjust(7)
    toti = data[:total_invoice ].to_s.rjust(7)

    st   = data[:salary_total  ].to_s.rjust(18)

    box = TextBox.new
    box.padding_horizontal = 3
    box.header = "Project:" + "\"#{data[:event]}\"".rjust(25)

    box.add_line  "Kosten       : #{co} -> #{ci}"
    box.add_line  "MWST         : #{to} -> #{ti}"
    box.add_line  "Gehalt Total : #{st}"
    box.add_line  "-----------------".rjust 33
    box.add_line  "Netto        : #{toto} -> #{toti}"
    box.add_line  "Final        : #{fo} -> #{fi}"
    box.footer = "Errors: #{project.errors.length} (#{ project.errors.join ',' })" if project.errors.length >0
 
    pp data[:final_offer]
    pp data[:final_invoice]
    puts box
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_csv(projects)
    header = [
      'date',
      'invoice_long',
      'offer',
      'event', 'name', 'manager', 'time', 'costs', 'total', 'valid'
    ]
    puts header.to_csv
    projects.each do |p|
      line = [
        p.data[:date],
        p.data[:invoice_number_long],
        p.data[:offer_number],
        p.data[:event],
        p.data[:name],
        p.data[:manager],
        p.data[:time].to_s + 'h',
        p.data[:costs_invoice],
        p.data[:total_invoice],
        p.valid_for[:invoice]
      ]
      line.map! {|v| v ? v : "" } # wow, that looks cryptic
      puts line.to_csv
    end
  end

  def pick_project(selection, year = nil)
    index = selection.to_i

    plumber = ProjectsPlumber.new $SETTINGS
    names = []; paths = []

    if(year)
      unsorted_paths = plumber.list_projects :archive, year
    else
      unsorted_paths = plumber.list_projects
    end
    projects = open_projects unsorted_paths
    projects.each {|p| names.push p.data[:name]; paths.push p.data[:project_path]
    }


    if index == 0 and names.include? selection
      return paths[names.index selection]
    elsif index > 0 
      return paths[index-1]
    else
      error "Invalid selection \"#{selection}\""
    end
  end
  
  def check_project(path)
    project = InvoiceProject.new $SETTINGS
    project.open path
    project.validate(:offer)
    unless project.data[:valid]
      puts "\nWARNING: the file you just edited contains errors! (#{project.errors})"
      unless no? "would you like to edit it again? [y|N]"
        edit_file path
      end
    end
  end
  #
  ## hand path to editor and check
  def edit_project(path, editor = $SETTINGS['editor'])
    edit_file path, editor
    #check_project path #TODO
  end

  ## hand path to editor
  def edit_file(path, editor = $SETTINGS['editor'])
    editor = $SETTINGS['editor'] unless editor
    logs "Opening #{path} in #{editor}"
    pid = spawn "#{editor} #{path}"
    Process.wait pid
  end

  def error(msg)
    STDERR.puts("ERROR: #{msg}")
    exit 1
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
