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
      project = InvoiceProject.new path
      project.validate validation
      projects.push project
    end
    #unsortable = Array.new(projects).delete_if  { |project| project.data[sort] }
    #unsortable.each   { |project| warn "#{project.data[:name]} not sortable by #{sort}"}
    #projects.keep_if  { |project| project.data[sort] }
    # TODO implement sortability in Project Plumber
    projects.sort_by! { |project| project.date }
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

      if p.data[:time]
        event.dtstart     = p.data[:time]
        event.dtend       = p.data[:time_end]
      else
        event.dtstart = Icalendar::Values::Date.new p.data[:date].strftime "%Y%m%d"
        event.dtend   = Icalendar::Values::Date.new((p.data[:date_end]+1).strftime "%Y%m%d")
      end 
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
      'invoice_long',
      'event',
      'date',
      'manager',
      'hours',
      'costs',
      'total',
      'valid'
    ]
    puts header.to_csv(col_sep:";")
    projects.each do |p|
       caterers_string = ""
       caterers_string = p.data[:hours][:caterers].map{|name, hours|"#{name} (#{hours})"}.join ", " if p.data[:caterers]
      line = [
        p.data[:invoice_number],
        p.data[:event],
        p.data[:date],
        p.data[:manager],
        caterers_string,
        p.data[:hours][:time].to_s + 'h',
        p.data[:costs_invoice],
        p.data[:total_invoice],
      #  p.valid_for[:invoice]
      ]
      line.map! {|v| v ? v : "" } # wow, that looks cryptic
      puts line.to_csv(col_sep:";")
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

end
