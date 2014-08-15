# encoding: utf-8
require 'icalendar'
libpath = File.dirname __FILE__
require File.join libpath, "shell.rb"

module AsciiInvoicer

  include Shell
  ## Use Option parser or leave it if only one argument is given

  def render_project project, choice
    project.validate choice
    if project.valid_for[choice]
      project.create_tex choice, options[:check]
    else
      error "#{project.name} is not ready for creating an #{choice.to_s}! #{project.data[:valid]} #{project.ERRORS if project.ERRORS.length > 0}"
    end
  end

  ##TODO turn color_from_date(date) into a loopuk into $SETTINGS
  def color_from_date(date)
    diff = date - Date.today
    return (rand * 256**3).to_i.to_s(16) if Date.today.day == 1 and Date.today.month == 4 #april fools
    return :magenta if diff < -28
    return :cyan    if diff < 0
    return :inverse if diff == 0
    return :red     if diff < 7
    return :yellow  if diff < 14
    return :green
  end

  def print_project_list projects, hash = {}
    table = TableBox.new
    projects.each_index do |i|
      project  = projects[i]
      if !hash[:colors].nil? and hash[:colors]
        color = color_from_date(project.date)
        color = :default if project.validate(:invoice)
      end
      if hash[:verbose]
        row = print_row_verbose project, hash
      else
        row = print_row_simple project, hash
      end
      if hash[:show_caterers] and project.data[:hours][:caterers]
      row << project.data[:hours][:caterers].keys.join(", ")
      end
      row << project.blockers(:invoice)      if hash[:show_blockers]
      row << project.ERRORS                  if hash[:show_errors] and project.STATUS == :ok
      row << project.STATUS                  if hash[:show_errors] and project.STATUS == :canceled
      row.insert 0, i+1
      table.add_row row, color
    end
    table.set_alignments(:r, :l, :l)
    puts table
  end

  def print_row_simple(project,hash) 
    row = [
      project.name.ljust(35), 
      project.data[:manager], 
      project.data[:event][:invoice_number], 
      project.data[:event][:date].strftime("%d.%m.%Y"), 
      #project.index
    ]
    return row
  end


  def print_row_verbose (project, hash)
    row = [
      project.name,
      project.data[:event][:name] ? project.data[:event][:name] : "",
      project.data[:manager],
      project.data[:invoice][:number],
      project.date.strftime("%d.%m.%Y"),
      project.validate(:invoice).print,
    ]
    return row
  end

  def print_project_list_paths(projects)
    table = TableBox.new
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

  def events_from_project(project)
      events = []
      p = project
      p.data[:event][:dates].each { |date|
        event = Icalendar::Event.new

        if date[:time] and date[:time][:begin]
          ## set specific times
          event.dtstart     = date[:time][:begin]
          event.dtend       = date[:time][:end]

        else
          ## set full day event
          event.dtstart = Icalendar::Values::Date.new( date[:begin].strftime  "%Y%m%d")
          event.dtend   = Icalendar::Values::Date.new((date[:end]+1).strftime "%Y%m%d")
        end 

        event.description = ""
        event.summary     = p.data[:event][:name]
        event.summary   ||= p.name

        event.description += "Verantwortung: " + p.data[:manager]      + "\n" if p.data[:manager]
        if p.data[:hours][:caterers]
          event.description +=  "Caterer:\n"
          p.data[:caterers].each {|caterer,time|
            event.description +=  " - #{ caterer}\n"
          }
        end

        event.description += p.data[:description]  + "\n" if p.data[:description]

        events.push  event unless event.dtstart.nil?
      }
      return events
  end

## TODO print_project_list_ical(projects) add products list
  def print_project_list_ical(projects)
    cal = Icalendar::Calendar.new
    projects.each_index do |i|
      events = events_from_project projects[i]
      events.each { |event| cal.add_event event }
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
    ]
    puts header.to_csv(col_sep:";")
    projects.each do |p|
      caterers_string = ""
      caterers_string = p.data[:hours][:caterers].map{|name, hours|"#{name} (#{hours})"}.join ", " if p.data[:hours][:caterers]
      line = [
        p.data[:invoice][:number],
        p.data[:event][:name],
        p.data[:event][:date],
        p.data[:invoice][:date],
        caterers_string,
        p.data[:manager].words[0],
        p.data[:invoice][:payed_date],
        #  p.valid_for[:invoice]
      ]
      line.map! {|v| v ? v : "" } # wow, that looks cryptic
      puts line.to_csv(col_sep:";")
    end
  end

  def display_products project, choice = :offer
    table = TableBox.new
    table.style[:border] = true
    table.title = "Project:" + "\"#{project.data[:event][:name]}\"".rjust(25)
    table.add_row ["#", "name", "price", "cost"]
    table.set_alignments :r, :l, :r, :r
    project.data[:products].each {|product|
      amount = product.amount choice
      price = product.price
      cost  = product.cost choice
      table.add_row [amount, product.name, price, cost]
    }

    return table
  end

  def display_costs project 
    data = project.data

    co   = data[:offer][:cost].to_s.rjust(7)
    ci   = data[:invoice][:cost].to_s.rjust(7)

    to   = data[:offer][:tax].to_s.rjust(7)
    ti   = data[:invoice][:tax].to_s.rjust(7)

    fo   = data[:offer][:final].to_s.rjust(7)
    fi   = data[:invoice][:final].to_s.rjust(7)

    toto = data[:offer][:total].to_s.rjust(7)
    toti = data[:invoice][:total].to_s.rjust(7)

    st   = data[:hours][:total].to_s.rjust(18)

    box = TableBox.new
    box.padding_horizontal = 3
    box.style[:border] = true
    box.title = "Project:" + "\"#{data[:event][:name]}\"".rjust(25)

    box.add_row  ["Kosten       :","#{co} -> #{ci}"]
    box.add_row  ["MWST         :","#{to} -> #{ti}"]
    box.add_row  ["Gehalt Total :","#{st}"]
    box.add_row  [nil, "-----------------"]
    box.add_row  ["Netto        :","#{toto} -> #{toti}"]
    box.add_row  ["Final        :","#{fo} -> #{fi}"]
    box.footer = "Errors: #{project.ERRORS.length} (#{ project.ERRORS.join ',' })" if project.ERRORS.length >0
    box.set_alignment 1, :r

    return box
  end

  def check_project(path)
    project = InvoiceProject.new $SETTINGS
    project.open path
    unless project.validate(:offer)
      puts "\nWARNING: the file you just edited contains errors! (#{project.ERRORS})"
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

end
