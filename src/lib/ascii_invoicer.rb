module AsciiInvoicer
  ## Use Option parser or leave it if only one argument is given

  def print_project_list(projects)
    print_project_list_plain projects
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_colored(projects)
    projects.each_index do |i|
      invoice   = projects[i]


      number    = (i+1).to_s
      name      = invoice['name']
      signature = invoice['signature']
      rnumber   = invoice['rnumber']
      rnumber   = "R" + rnumber.to_s.rjust(3,'0') if rnumber.class == Fixnum
      date      = invoice['date']

      number    = number.rjust 4
      name      = name.ljust 34
      signature = signature.ljust 17
      rnumber   = rnumber.to_s.ljust 4
      date      = date.rjust 15

      number    = Paint[number, :bright]
      name      = Paint[name, [145,145,145], :clean] if invoice['raw_date'].to_date <= Date.today
      name      = Paint[name, [255,0,0], :bright ]   if invoice['raw_date'].to_date - Date.today < 7
      name      = Paint[name, [255,255,0] ]          if invoice['raw_date'].to_date - Date.today < 14
      name      = Paint[name, [0,255,0] ]            if invoice['raw_date'].to_date - Date.today >= 14
      signature = signature
      rnumber   = rnumber
      date      = date

      line = "#{number}. #{name} #{signature} #{rnumber} #{date}"



      puts line
      #unless projects[i+1].nil?
      #  if invoice['raw_date'] <= Time.now and projects[i+1]['raw_date'] > Time.now
      #    padding = Paint.unpaint(number).length + 3
      #    plain_line = Paint.unpaint line
      #    divider = ''.rjust(padding).ljust(plain_line.length-padding, '█')
      #    puts divider
      #  end
      #end
      #puts "R#{invoice['rnumber'].to_s}, #{invoice['name']}, #{invoice['signature']}, #{invoice['date']}"
    end
  end

  #takes an array of invoices (@plumber.working_projects)
  def print_project_list_csv(projects)
    projects.each_index do |i|
      invoice   = projects[i]
      number    = (i+1).to_s
      name      = invoice['name']
      signature = invoice['signature']
      rnumber   = invoice['rnumber']
      rnumber   = "R" + rnumber.to_s.rjust(3,'0') if rnumber.class == Fixnum
      date      = invoice['raw_date']
      line = "#{rnumber}, #{name}, \"#{signature}\", #{date}"
      puts line
    end
  end

  def print_project_list_plain(projects)
    projects.each_index do |i|
      invoice   = projects[i]

      number    = (i+1).to_s
      number    = number.rjust 4
      name      = invoice['name'].ljust 34
      signature = invoice['signature'].ljust 17
      rnumber   = invoice['rnumber']
      rnumber   = "R" + rnumber.to_s.rjust(3,'0') if rnumber.class == Fixnum
      rnumber   = rnumber.to_s.ljust 4
      date      = invoice['date'].rjust 15

      line = "#{number}. #{name} #{signature} #{rnumber} #{date}"
      puts line
    end
  end


  ## hand path to editor
  def edit_file(path)
    puts "Opening #{path} in #{$settings.editor}"
    pid = spawn "#{$settings.editor} #{path}"
    Process.wait pid
  end


  ## creates a  latex file from NAME of the desired TYPE
  def write_tex(name, type)
    return false unless @plumber.check_project name
    path    = @plumber.get_project_file name
    pfolder = @plumber.get_project_folder name

    invoicer = Invoicer.new
    invoicer.load_templates :invoice => @options.template_invoice , :offer => @options.template_offer
    invoicer.read_file path

    invoicer.type = type
    invoicer.project_name = name
    if name.nil? or name.size == 0 
      if invoicer.dump['event'].nil? or invoicer.dump['event'].size == 0
        name = path.tr '/', '_'
        puts name
      else
        name = invoicer.dump['event']
        puts "name taken from event \"#{name}\""
      end
    end

    if invoicer.is_valid or true
      tex = invoicer.create

      d = invoicer.dump

      # datei namen
      case type
      when :invoice
        datestr = d['raw_date'].strftime("%Y-%m-%d")
        filename = "R#{d['rnumber'].to_s.rjust 3, "0"} #{name} #{datestr}.tex"
        file = "#{pfolder}"+filename
      when :offer
        #datestr = d['raw_date'].strftime("%y%m%d") # date of invoice
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
      puts "invoice is not valid"
    end
  end
end
