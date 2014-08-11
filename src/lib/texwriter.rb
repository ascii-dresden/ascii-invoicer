module TexWriter

  ##
  # fills the template with mined DATA
  def create_tex type, stdout = true
    document_template = load_template :document
    document_type     = type
    return fail_at :templates unless document_template

    unless validate(type)
      error "Cannot create an \"#{type.to_s}\" from #{@data[:name]}. (#{@ERRORS.join ','})"
    end

    #check output path first
    output_path = File.expand_path $SETTINGS['output_path']
    unless File.directory? output_path
      error "your output_path is not a directory! (#{output_path})"
    end

    #set the output filename
    filename = export_filename type, "tex"

    puts "% #{filename}"
    # fill out ERB (twice), make sure everything's set
    template = ERB.new(document_template).result(binding)
    result   = ERB.new(template).result(binding)

    output_path = File.join @PROJECT_FOLDER, filename
 
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
    logs "file written: #{path}"
    rescue
      error "Unable to write into #{path}"
    end
  end

  def render_tex path, filename
    logs "Rendering #{path} with #{$SETTINGS['latex']}"
    silencer = $SETTINGS['verbose'] ? "" : "> /dev/null" 

## TODO output directory is not generic
    system "#{$SETTINGS['latex']} \"#{path}\" -output-directory . #{silencer}"

    output_path = File.expand_path $SETTINGS['output_path']
    error "your output_path is not a directory! (#{output_path})" unless File.directory? output_path

    pdf = filename.gsub('.tex','.pdf')
    log = filename.gsub('.tex','.log')
    aux = filename.gsub('.tex','.aux')
    unless $SETTINGS['keep_log']
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
      error "#{pdf} does not exist, so it can not be moved to #{output_path}"
    elsif File.expand_path(output_path)!= FileUtils.pwd
      FileUtils.mv pdf, output_path, :force => true, :verbose => true
    end


    puts "Created #{path}"
  end

  ##
  # loads template files named in settings
  def load_template(type)
    path = File.join $SETTINGS['script_path'],
      $SETTINGS['templates'][type.to_s]
    if File.exists?(path)
      return File.open(path).read
    else
      error "Template (#{path}) File not found!"
      return false
    end
  end


end
