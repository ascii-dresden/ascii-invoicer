# encoding: utf-8
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
      error "#{project.name} is not ready for creating an #{choice.to_s}! #{project.data[:valid]} #{project.errors if project.errors.length > 0}"
    end
  end

  ##TODO turn color_from_date(date) into a loopuk into $SETTINGS
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
        p.data[:event][:invoice_number], 
        p.data[:event][:date].strftime("%d.%m.%Y"), 
      ], color_from_date(p.date))
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
        p.data[:event][:name] ? p.data[:event][:name] : "",
        p.name,
        p.data[:manager],
        p.data[:invoice][:number],
        p.data[:event][:date].strftime("%d.%m.%Y"),
        p.validate(:invoice).print,
        #p.ERRORS,
      ], color_from_date(p.date))
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

## TODO print_project_list_ical(projects) add products list
  def print_project_list_ical(projects)
    require 'icalendar'
    cal = Icalendar::Calendar.new
    projects.each_index do |i|
      p  = projects[i]

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
        if p.data[:caterers]
          event.description +=  "Caterer:\n"
          p.data[:caterers].each {|caterer|
            event.description +=  " - #{ caterer}\n"
          }
        end

        if p.data[:products]
          event.description +=  "Produkte:\n"
        end

        event.description += p.data[:description]  + "\n" if p.data[:description]

        cal.add_event event unless event.dtstart.nil?
      }

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
    puts "TODO implement print_project_list_csv()"
    return
    header = [
      'invoice',
      'event',
      'date',
      'manager',
      'hours',
      'costs',
      'total',
    ]
    puts header.to_csv(col_sep:";")
    projects.each do |p|
      caterers_string = ""
      caterers_string = p.data[:hours][:caterers].map{|name, hours|"#{name} (#{hours})"}.join ", " if p.data[:caterers]
      line = [
        p.data[:invoice][:number],
        p.data[:event][:name],
        p.data[:event][:date],
        p.data[:manager],
        caterers_string,
        p.data[:hours][:total].to_s + 'h',
        p.data[:invoice][:costs],
        p.data[:invoice][:total],
        #  p.valid_for[:invoice]
      ]
      line.map! {|v| v ? v : "" } # wow, that looks cryptic
      puts line.to_csv(col_sep:";")
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
