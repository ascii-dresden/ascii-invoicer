module TexWriter

  ##
  # fills the template with mined DATA
  def create_tex choice, check = false, run = true
    return fail_at :create_tex unless parse :products
    return fail_at :templates unless load_templates()

    unless valid_for[choice] or check
      error "Cannot create an \"#{choice.to_s}\" from #{@DATA[:name]}. (#{@errors.join ','})"
    end

    output_path = File.expand_path @settings['output_path']
    error "your output_path is not a directory! (#{output_path})" unless File.directory? output_path

    template = @template_invoice if choice == :invoice
    template = @template_offer   if choice == :offer

    template = ERB.new(template).result(binding)
    result   = ERB.new(template).result(binding)

    filename = export_filename choice, "tex"
    output_path = File.join @project_folder , filename
 
    puts output_path
    write_to_file result, output_path
    render_tex output_path, filename if run
  end

  def render_tex path, filename
    logs "Rendering #{path} with #{@settings['latex']}"
    silencer = @settings['verbose'] ? "" : "> /dev/null" 

## TODO output directory is not generic
    system "#{@settings['latex']} \"#{path}\" -output-directory . #{silencer}"

    output_path = File.expand_path @settings['output_path']
    error "your output_path is not a directory! (#{output_path})" unless File.directory? output_path

    pdf = filename.gsub('.tex','.pdf')
    log = filename.gsub('.tex','.log')
    aux = filename.gsub('.tex','.aux')
    unless @settings['keep_log']
      FileUtils.rm log if File.exists? log
      FileUtils.rm aux if File.exists? aux
    else
      unless File.expand_path output_path == FileUtils.pwd
        FileUtils.mv log, output_path if File.exists? log
        FileUtils.mv aux, output_path if File.exists? aux
      end
    end
    FileUtils.mv pdf, output_path if File.exists? pdf


    puts "Created #{path}"
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
  ##
  # loads template files named in settings
  def load_templates()
    offer   = File.join $SETTINGS['script_path'], $SETTINGS['templates']['offer']
    invoice = File.join $SETTINGS['script_path'], $SETTINGS['templates']['invoice']
    if File.exists?(offer) and File.exists?(invoice)
      @template_invoice = File.open(invoice).read
      @template_offer   = File.open(offer).read
      return true
    else
      error "Template File not found!"
    end
    return false
  end


end
