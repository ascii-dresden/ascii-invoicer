# encoding: utf-8
module AsciiInvoicer
  ## Use Option parser or leave it if only one argument is given

  def render_project project, choice
    project.validate choice
    if project.valid_for[choice]
      project.create_tex choice, options[:check]
    else
      error "#{project.name} is not ready for creating an #{choice.to_s}! #{project.data[:valid]} #{project.errors if project.errors.length > 0}"
    end
  end

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

  def color_from_date(date)
    return nil      unless $SETTINGS['colors']
    return :blue    if date - Date.today < -14
    return :default if date < Date.today
    return :red     if date - Date.today < 7
    return :yellow  if date - Date.today < 14
    return :green   if date - Date.today >= 14
    return :white
  end


  def print_project_list_simple(projects)
    table = TableBox.new
    table.style[:border] = false
    projects.each_index do |i|
      p  = projects[i]
      table.add_row([
        (i+1).to_s+".", 
        p.name.ljust(35), 
        p.data[:manager], 
        p.data[:invoice_number], 
        p.data[:date].strftime("%d.%m.%Y"), 
      ], color_from_date(p.data[:date]))
    end
    table.set_alignments(:r, :l, :l)
    puts table
  end

  def print_project_list_verbose(projects)
    table = TableBox.new
    table.style[:border] = false
    projects.each_index do |i|
      p  = projects[i]
      table.add_row([
        (i+1).to_s+".",
        p.data[:event] ? p.data[:event] : "",
        p.name,
        p.data[:manager],
        p.data[:invoice_number],
        p.data[:date].strftime("%d.%m.%Y"),
        p.data[:valid].print,
      ], color_from_date(p.data[:date]))
    end
    table.set_alignment(0, :r)
    table.set_alignment(5, :r)
    puts table
  end

  def print_project_list_paths(projects)
    table = TableBox.new
    projects.each_index do |i|
      p  = projects[i]
      table.add_row [
        (i+1).to_s+".", 
        p.data[:name].ljust(35), 
        p.data[:project_path]
      ]
    end
    table.set_alignments(:r, :l, :l)
    puts table
  end

  def print_project_list_ical(projects)
    cal = Icalendar::Calendar.new
    projects.each_index do |i|
      p  = projects[i]
      event = Icalendar::Event.new

      event.dtstart     = p.data[:date]
      event.dtend       = p.data[:date_end]
      event.description = ""
      if p.data[:event]
        event.summary      = p.data[:event]
        #event.description += "(#{p.data[:name]})\n"
      else
        event.summary     = p.name
      end

      event.description += "Verantwortung: " + p.data[:manager]      + "\n" if p.data[:manager]
      if p.data[:caterers]
        event.description +=  "Caterer:\n"
        p.data[:caterers].each {|caterer|
          event.description +=  " - #{ caterer}\n"
        }
      end

      if p.data[:products]
        event.description +=  "Produkte:\n"
        p.data[:products].each {|name, product|
          event.description +=  " - #{ product.amount :offer } #{ name}\n"
        }
      end


      event.description += p.data[:description]  + "\n" if p.data[:description]

      cal.add_event event
    end
    puts cal.to_ical
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_yaml(projects)
    projects.each do |p|
      puts p.data.to_yaml
      puts "...\n\n"
    end
  end

  def display_products project, choice = :offer
    table = TableBox.new
    table.style[:border] = true
    table.title = "Project:" + "\"#{project.data[:event]}\"".rjust(25)
      table.add_row ["#", "name", "price", "cost"]
    project.data[:products].each {|name, product|
      amount = product.amount choice
      price = product.price
      cost  = product.cost choice
      table.add_row [amount, name, price, cost]
    }

    return table
  end

  def display_costs project 
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

    box = TableBox.new
    box.padding_horizontal = 3
    box.style[:border] = true
    box.title = "Project:" + "\"#{data[:event]}\"".rjust(25)

    box.add_row  ["Kosten       :","#{co} -> #{ci}"]
    box.add_row  ["MWST         :","#{to} -> #{ti}"]
    box.add_row  ["Gehalt Total :","#{st}"]
    box.add_row  [nil, "-----------------"]
    box.add_row  ["Netto        :","#{toto} -> #{toti}"]
    box.add_row  ["Final        :","#{fo} -> #{fi}"]
    box.footer = "Errors: #{project.errors.length} (#{ project.errors.join ',' })" if project.errors.length >0
    box.set_alignment 1, :r
 
    return box
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_csv(projects)
    header = [
      'date', 'invoice_long',
      'offer',
      'event', 'name', 'manager', 'hours', 'costs', 'total', 'valid'
    ]
    puts header.to_csv
    projects.each do |p|
      line = [
        p.data[:date],
        p.data[:invoice_number_long],
        p.data[:offer_number],
        p.data[:event],
        p.name,
        p.data[:manager],
        p.data[:hours][:time].to_s + 'h',
        p.data[:costs_invoice],
        p.data[:total_invoice],
        p.valid_for[:invoice]
      ]
      line.map! {|v| v ? v : "" } # wow, that looks cryptic
      puts line.to_csv
    end
  end

  def pick_paths( hash, archive = nil)
    paths = hash.map { |index|
      if options[:file]
        options[:file]
      else
        pick_project index, archive
      end
    }
    #project = InvoiceProject.new $SETTINGS, path
    paths.select! {|item| not item.nil?}
    return paths
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
    projects.each {|p| names.push p.data[:name]; paths.push p.data[:project_path] }


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
        edit_files path
      end
    end
  end

  ## hand path to editor
  def edit_files(paths, editor = $SETTINGS['editor'])
    paths = [paths] if paths.class == String
    paths.map!{|path| "\"#{path}\"" }
    paths = paths.join ' '
    editor = $SETTINGS['editor'] unless editor
    logs "Opening #{paths} in #{editor}"
    pid = spawn "#{editor} #{paths}"
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
      tex = project.create_tex

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
