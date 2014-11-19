# encoding: utf-8

require 'paint'

require File.join File.dirname(__FILE__) + '/tweaks.rb'
require File.join File.dirname(__FILE__) + '/filters.rb'


module ProjectFileReader
  # reads    @raw_data
  # fills    @data
  # uses     @defaults
  # produces @errors
  # has a    @status

  ##
  # little read function
  # returns data if read already
  # or does a lookup
  def read(key, data = @data)
    return nil unless key.class == Symbol

    # data has already been read
    @reader_logger.info Paint["KNOWN KEY: #{key}",:cyan] if data[key] if @settings.DEBUG
    return data[key]         if data[key]

    @reader_logger.info Paint["reading :#{key}", :green, :bold] if @settings.DEBUG

    raw     = @raw_data[key.to_s]
    default = @defaults[key.to_s]

    # if key is in raw_data walk it trough applying filters
    if raw
      @reader_logger.info "    FOUND RAW #{key}" if @settings.DEBUG
      @reader_logger.info "     walking #{key}" if @settings.DEBUG
      return data[key]  = walk(raw, [key])
      #fail "#{self.class} DOES NOT KNOW WHAT TO DO WITH #{raw.class}"
    end

    # or the default from the settings
    unless default.nil?
      @reader_logger.info "    FOUND DEFAULT #{key}" if @settings.DEBUG
      return data[key] = walk(default, [key])
    end

    # otherwise fail
    return data[key] = fail_at(key)
  end

  private
  def walk(tree= @raw_data, path = [])
    catch :filter_error do
      if tree.class == Hash
        new_tree = {}
        tree.each{|k,v|
          k = k.to_sym if k.class == String
          k = walk(k, path+[k] )if k.class == Hash
          new_tree[k] = walk(v, path+[k])
        }
        new_tree = apply_filter path, new_tree
        return new_tree
      elsif tree.class == Array
        new_tree = []
        tree.each_index{|i|
          v = tree[i]
          new_tree[i] = walk(v, path+[i])
        }
        new_tree = apply_filter path, new_tree
        return new_tree
      else
        tree = apply_filter path, tree
        return tree
      end
    end
  end

  def apply_generator(path, value)
    apply_filter path, value, "generate_"
  end

  def apply_filter(path, value, prefix = "filter_")
    begin
      path = path.join('_') if path.class == Array
      path = path.to_s      if path.class == Symbol
      parser = prefix+path
      begin parser = method(parser)
      rescue NameError
        return value
      else
        @reader_logger.info Paint[path, :yellow] if @settings.DEBUG
        return parser.call(value)
      end
    end
    rescue => error
      fail_at path
      puts Array.new($@).keep_if{|line| line.include? "filter_"}.map {|line| Paint[line, :red, :bold]}
      puts Array.new($@).keep_if{|line| line.include? "generate_"}.map {|line| Paint[line, :blue, :bold]}
      puts Paint["      #{error} (#{@project_path})", :yellow]
    end

  def fail_at(*criteria)
    @data[:valid] = false
    criteria.each  {|c|
      @errors.push c.to_sym unless @errors.include? c
    }
    return nil
  end

end
