require 'fileutils'

require 'hash-graft'
require 'hashr'
require 'yaml'

# all about settings
class SettingsManager
  attr_reader :settings, :homedir_settings, :default_settings

  #expacting :homedir_path, :default_path, #template_path
  def initialize hash
    @init_hash = Hashr.new hash

    raise "SettingsManager: No default file given." unless @init_hash.default_path?
    raise "SettingsManager: No homedir file given." unless @init_hash.homedir_path?

    @init_hash.default_path  = File.expand_path @init_hash.default_path
    @init_hash.homedir_path  = File.expand_path @init_hash.homedir_path
    @init_hash.template_path = File.expand_path @init_hash.template_path if @init_hash.template_path?

    if File.exists?(@init_hash.default_path)
      @default_settings = load_file @init_hash.default_path
    else
      raise "SettingsManager: Default settings file does not exist (#{@init_hash.default_path})."
    end

    if not File.exists?(@init_hash.homedir_path)
      if @init_hash.template_path?
        raise "SettingsManager: Template file does not exist" unless File.exists?(@init_hash.template_path)
        puts "#{@init_hash.homedir_path} does not exist, but #{@init_hash.homedir_path} does"
        puts "-> copying over"
        FileUtils.cp @init_hash.template_path, @init_hash.homedir_path
      else
        # using only default_settings
        # suggested use: used a default_settings as template, perhaps comment out everything
      end
    else
      @homedir_settings = load_file @init_hash.homedir_path
    end

    # putting it all together
    @settings = Hashr.new @default_settings.graft @homedir_settings
    @settings.settings_homedir_path = @homedir_settings
    @settings.settings_deafult_path = @default_settings
    return @settings
  end

  def load_file path
    begin
      YAML::load File.open File.expand_path path
    rescue SyntaxError => error
      puts "ERROR parsing #{File.expand_path path}!"
      puts error
    end
  end
end
