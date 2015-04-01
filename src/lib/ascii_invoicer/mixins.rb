require 'icalendar'
require 'fileutils'

module AsciiMixins

  ## Use Option parser or leave it if only one argument is given

  def render_project project, choice
    project.validate choice
    if project.valid_for[choice]
      project.create_tex choice, options[:check]
    else
      $logger.error "#{project.name} is not ready for creating an #{choice.to_s}! #{project.data[:valid]} #{project.errors if project.errors.length > 0}"
    end
  end

  ##TODO turn color_from_date(date) into a loopuk into $SETTINGS
  def color_from_date(date)
    diff = date - Date.today
    return (rand * 256**3).to_i.to_s(16) if Date.today.day == 1 and Date.today.month == 4 #april fools
    return :magenta                      if diff < -28
    return :cyan                         if diff < 0
    return [:yellow,:bright]             if diff == 0
    return :red                          if diff < 7
    return :yellow                       if diff < 14
    return [:green]
  end

  def print_project_list projects, hash = {}
    table = Textboxes.new
    table.style[:border]             = false
    table.style[:column_borders]     = false
    table.style[:row_borders]        = false
    table.style[:padding_horizontal] = 1
    projects.each_index do |i|
      project  = projects[i]
      if  Date.today.day == 1 and Date.today.month == 4
        color = color_from_date(project.date)
      elsif !hash[:colors].nil? and hash[:colors]
        color = color_from_date(project.date)
        color = :default if project.validate(:invoice)
        color = [:blue] if project.status == :canceled
      end
      if hash[:verbose]
        row = print_row_verbose project, hash
      else
        row = print_row_simple project, hash
      end

      row << caterers_string(project) if hash[:caterers] and project.data[:hours][:caterers]

      row << project.blockers(:archive)      if hash[:blockers]
      if hash[:details]
        hash[:details].each {|detail|
          row << project.data.get_path(detail)
        }
      end

      row << project.errors                  if hash[:errors] and project.status == :ok
      row << project.status                  if hash[:errors] and project.status == :canceled
      row.insert 0, i+1
      table.add_row row, color
    end
    table.set_alignments(:r, :l, :l)
    puts table
  end

  def print_row_simple(project,hash) 
    row = [
      project.pretty_name,
      project.data[:manager],
      project.data[:event][:invoice_number],
      project.data[:event][:date].strftime("%d.%m.%Y"),
      #project.index
    ]
    return row
  end

  def print_row_verbose (project, hash)
    name = "##{project.data[:name]}#"
    if not project.data[:event][:name].nil? and project.data[:event][:name].size > 0
      name = project.data[:event][:name]
      name = "CANCELED: " + name if project.data :canceled
    end
    row = [
      name,
      project.data[:manager],
      project.data[:invoice][:number],
      project.date.strftime("%d.%m.%Y"),
      project.state_sign(:offer),
      project.state_sign(:invoice),
      project.validate(:payed).print($SETTINGS.currency_symbol),
      # try these: ☑☒✉☕☀☻
    ]
    return row
  end

  def print_project_list_paths(projects)
    table = Textboxes.new
    projects.each_index do |i|
      p  = projects[i]
      table.add_row [
        (i+1).to_s+".",
        p.name.ljust(35),
        p.data[:project_path]
      ]
    end
    table.set_alignments(:r, :l, :l)
    puts table
  end

  def create_cal_file(projects)
    cal = Icalendar::Calendar.new
    projects.each_index do |i|
      project = projects[i]
      events = project.data[:event][:calendaritems]
      if events
        events.each { |event| cal.add_event event}
      else
        $logger.warn "Calendar can't be parsed. (#{project.data[:name]})", :file
      end
    end

    cal_file_path = File.join(FileUtils.pwd, $SETTINGS.calendar_file)
    cal_file = File.open(cal_file_path, ?w)
    cal_file.write cal.to_ical
    puts "created #{cal_file_path}"
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_yaml(projects)
    projects.each do |p|
      puts p.data.to_yaml
      puts "...\n\n"
    end
  end

  def caterers_string project, join = ", "
      data = project.data
      data[:hours][:caterers].map{|name, hours| "#{name} (#{hours})" if hours > 0 }.join join if data[:hours][:caterers]
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_csv(projects)
    header = [
      'Rnum',
      'Bezeichnung',
      'Datum',
      'Rechnungsdatum',
      'Betreuer',
      'verantwortlich',
      'Bezahlt am',
      'Betrag',
      'Canceled',
    ]
    puts header.to_csv(col_sep:";")
    projects.each do |p|
      canceled = ""
      canceled = "canceled" if p.data[:canceled]
      line = [
        p.data[:invoice][:number],
        p.data[:event][:name],
        p.data[:event][:date],
        p.data[:invoice][:date],
        caterers_string(p),
        p.data[:manager].words[0],
        p.data[:invoice][:payed_date],
        p.data[:invoice][:final],
        canceled,
        #  p.valid_for[:invoice]
      ]
      canceled = "canceled" if p.data[:canceled]
      line.map! {|v| v ? v : "" } # wow, that looks cryptic
      puts line.to_csv(col_sep:";")
    end
  end

  def display_products project, choice = :offer, standalone = true
    table = Textboxes.new
    table.style[:border] = standalone
    table.title = "Project:" + "\"#{project.data[:event][:name]}\"".rjust(25) if standalone
    table.add_row ["#", "name", "price", "cost"]
    table.set_alignments :r, :l, :r, :r
    project.data[:products].each {|product|
      amount = product.amount choice
      price = product.price
      cost  = product.cost choice
      table.add_row [amount, product.name, price, cost]
    }
    table.add_row ["#{project.data[:hours][:time]}h", "service" , project.data[:hours][:salary], project.data[:hours][:total]] if project.data.get_path('hours/time').to_i> 0
    table.add_row [nil, caterers_string(project)]

    return table
  end

  def display_all project, choice, show_errors = true
    raise "choice must be either :invoice or :offer" unless choice == :invoice or choice == :offer
    data = project.data

    table = Textboxes.new
    table.style[:border] = true
    table.title = "Project:" + "\"#{data[:event][:name]}\"".rjust(25)
    table.add_row [nil, "name", "amount","price", "cost"]
    table.set_alignments :r, :l, :r, :r, :r

    i = 0
    data[:products].each {|product|
      amount = product.amount choice
      price = product.price
      cost  = product.cost choice
      table.add_row [i+=1,product.name, amount, price, cost]
    }
    table.add_row [i+1,"service", "#{data[:hours][:time]}h",  data[:hours][:salary], data[:hours][:total]] if project.data.get_path('hours/time').to_i> 0

    separator = table.column_widths.map{|w| ?=*w}
    separator[0] = nil
    table.add_row separator

    table.add_row  [nil,"Kosten",nil,nil,"#{data[choice][:costs]}"]
    data[:productsbytax].each {|tax,products|
      tpv = 0.to_euro # tax per value
      tax = (tax.rationalize * 100).to_f
      products.each{|p|
        tpv += p.hash[:tax_offer]   if choice == :offer
        tpv += p.hash[:tax_invoice] if choice == :invoice
      }
      table.add_row  [nil, "MWST #{tax}%",nil,nil,"#{tpv}"]
    }
    table.add_row   [nil,  "Final", nil, nil, "#{data[choice][:final]}"]

    if show_errors
      table.footer = "Errors: #{project.errors.length} (#{ project.errors.join ',' })" if project.errors.length >0
    end

    return table
  end

  def display_products_csv project
    puts [['name', 'price', 'amount', 'sold', 'tax_value'].to_csv(col_sep:?;)]+
    project.data[:products].map{|p| p.to_csv(col_sep:?;)}
  end

  def check_project(path)
    project = InvoiceProject.new $SETTINGS
    project.open path
    unless project.validate(:offer)
      puts "\nWARNING: the file you just edited contains errors! (#{project.errors})"
      unless no? "would you like to edit it again? [y|N]"
        edit_files path
      end
    end
  end

  ## hand path to default programm
  def open_file path
    unless path.class == String and File.exists? path
      $logger.error "Cannot open #{path}", :both 
      return false
    end
    opener = $SETTINGS.opener
    $logger.info "Opening #{path} in #{opener}"
    pid = spawn "#{opener} \"#{path}\""
    Process.wait pid
  end

  ## hand path to editor
  def edit_files(paths, editor = $SETTINGS.editor)
    paths = [paths] if paths.class == String
    paths.select! {|path| path}
    if paths.empty?
      $logger.error "no paths to open"
      return false
    end
    paths.map!{|path| "\"#{path}\"" }
    paths = paths.join ' '
    editor = $SETTINGS.editor unless editor
    $logger.info "Opening #{paths} in #{editor}"
    pid = spawn "#{editor} #{paths}"
    Process.wait pid
  end

end
