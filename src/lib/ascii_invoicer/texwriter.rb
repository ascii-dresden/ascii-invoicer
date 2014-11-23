require 'logger'

module TexWriter

  ##
  # fills the template with mined DATA
  def create_tex type, stdout = true
    document_template = load_template :document
    document_type     = type
    return fail_at :templates unless document_template

    unless validate(type)
      @logger.error "Cannot create an \"#{type.to_s}\" from #{@data[:name]}. (#{blockers(type).join ','})"
    end

    #check output path first
    output_path = File.expand_path $SETTINGS.output_path
    unless File.directory? output_path
      @logger.error "your output_path is not a directory! (#{output_path})"
      exit
    end

    #set the output filename
    filename = export_filename type, "tex"

    puts "% #{filename}"
    # fill out ERB (twice), make sure everything's set
    template = ERB.new(document_template).result(binding)
    result   = ERB.new(template).result(binding)

    output_path = File.join @project_folder, filename
 
    puts result                       if  stdout
    write_to_file result, output_path if !stdout
    render_tex output_path, filename  if !stdout
  end

  def write_to_file file_content, path
    begin
    file = File.new path, ?w
    file_content.lines.each do |line|
      file.write line
    end
    file.close
    @logger.info "file written: #{path}"
    rescue
      @logger.error "Unable to write into #{path}"
    end
  end

  def render_tex path, filename
    @logger.info "Rendering #{path} with #{$SETTINGS.latex}"
    silencer = $SETTINGS.verbose ? "" : "> /dev/null" 

## TODO output directory is not generic
    system "#{$SETTINGS.latex} \"#{path}\" -output-directory . #{silencer}"

    output_path = File.expand_path $SETTINGS.output_path
    @logger.error "your output_path is not a directory! (#{output_path})" unless File.directory? output_path

    pdf = filename.gsub('.tex','.pdf')
    log = filename.gsub('.tex','.log')
    aux = filename.gsub('.tex','.aux')
    unless $SETTINGS.keep_log
      FileUtils.rm log if File.exists? log
      FileUtils.rm aux if File.exists? aux
    else
      unless File.expand_path output_path == FileUtils.pwd
        FileUtils.mv log, output_path if File.exists? log
        FileUtils.mv aux, output_path if File.exists? aux
      end
    end
    target = File.join output_path, pdf

    puts "moving #{pdf} to #{target}"
    if not File.exists? pdf
      @logger.error "#{pdf} does not exist, so it can not be moved to #{output_path}"
    elsif File.expand_path(output_path)!= FileUtils.pwd
      FileUtils.mv pdf, output_path, :force => true, :verbose => true
    end


    puts "Created #{path}"
  end

  # loads template files named in settings
  def load_template(type)
    return false unless $PLUMBER.check_dir :templates
    #files = Dir.glob File.join @dirs[:templates] , ?*
    files = Dir.glob File.join($PLUMBER.dirs[:templates], "*{tex.erb,tex}")
    templates =  {}
    files.each{|file|
      templates[File.basename(file.split(?.)[0]).to_sym] = file
    }
    path = templates[type] 
    if File.exists?(path)
      return File.open(path).read
    else
      @logger.error "Template (#{path}) File not found!"
      return false
    end
  end


end
