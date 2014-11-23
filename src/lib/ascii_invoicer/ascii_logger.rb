#http://stackoverflow.com/questions/6407141/how-can-i-have-ruby-logger-log-output-to-stdout-as-well-as-file
require 'logger'
require 'fileutils'

class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args); t.flush}
  end

  def close
    @targets.each(&:close)
  end
end

class AsciiLogger

  def initialize name, path
    path = File.expand_path path
    FileUtils.touch path
    @log_file = File.open path, ?a
    @known_loggers = [:file, :stdo, :both]
    @known_methods = [:info, :warn, :error, :fatal, :unknown]

    @file_logger = Logger.new MultiIO.new @log_file
    @stdo_logger = Logger.new STDOUT
    @both_logger = Logger.new MultiIO.new STDOUT, @log_file

    @file_logger.progname = name
    @stdo_logger.progname = name
    @both_logger.progname = name
  end

  def log logger_name, method_name, message
    raise "#{method_name}, unknown method type, use #{@known_methods}" unless @known_methods.include? method_name
    raise "#{logger_name}, unknown logger type, use #{@known_loggers}" unless @known_loggers.include? logger_name

    logger_name = "@#{(logger_name.to_s)}_logger".to_sym
    if instance_variables.include? logger_name
      logger = instance_variable_get logger_name
      logger.method(method_name).call message
    else
      puts "ERROR: logger not found (#{logger_name})"
    end
  end

  # imitates stdlib logger interface -> AsciiLogger::error message, {:stdo\:file\:both}
  def method_missing method_name, *stuff
    if @known_methods.include? method_name.to_sym
      message = stuff[0]
      logger  = stuff[1].to_sym if stuff[1]
      logger  = :both unless @known_loggers.include? logger
      log logger, method_name.to_sym, message
    end
  end

end
