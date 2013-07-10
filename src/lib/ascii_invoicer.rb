class AsciiInvoicer
  ## Use Option parser or leave it if only one argument is given
  def initialize (options)

    @options = options
    @plumber = ProjectsPlumber.new @options

    @options.projectname = pick_project @options.projectname
    if @options.operations.size == 0 
      unless @options.projectname.nil?
        @options.operations = [:edit]
      else
        @options.operations = [:list]
      end
    end


    end

    def execute
      project = pick_project @options.projectname # turns index numbers into names

      edit_project project               if @options.operations.include? :edit
      write_tex project, :invoice        if @options.operations.include? :invoice
      write_tex project, :offer          if @options.operations.include? :offer
      print_project_list                 if @options.operations.include? :list
      @plumber.archive_project project   if @options.operations.include? :archive
      @plumber.unarchive_project project if @options.operations.include? :unarchive

      if @options.operations.include? :new
        new_project project         
        edit_project project
      end
      dump_file project           if @options.operations.include? :dump
      sum_up project              if @options.operations.include? :sum

      if @options.verbose
        pp "operations:",   @options.operations
        pp "projectname:",  @options.projectname
        pp "project:",  project
        pp "project_file:",  @options.project_file
        if @options.veryverbose
          pp 'options:' ,     @options
        end
      end
    end



  ## open project file from name
  def pick_project input
    if (number = input.to_i) != 0
      error "invalid index" if number > @plumber.dirs.size
      @options.projectname = @plumber.ordered_dirs[number-1]
    else
      @options.projectname = input
    end
  end




  ## open project file from name
  def edit_project name
    edit_file @plumber.get_project_file name
  end

  ## hand path to editor
  def edit_file(path)
    puts "Opening #{path} in #{@options.editor}"
    pid = spawn "#{@options.editor} #{path}"
    Process.wait pid
  end

  def dump_file(project)
    file = @plumber.get_project_file project
    pp @plumber.open_project file
  end

  def sum_up(project)
    file = @plumber.get_project_file project
    project = @plumber.open_project file
    picks = ['event', 'summe', 'date']
    puts "\"#{project['event']}\":".ljust(30) + "#{project['summe'].rjust 8}"
  end



  ## pretty version list projects TODO: make prettier
  def print_project_list
    projects = @plumber.working_projects
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

  def new_project(name)
    @plumber.new_project name
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
        datestr = d['raw_date'].strftime("%y%m%d")
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
