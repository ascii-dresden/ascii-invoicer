# encoding: utf-8

require './lib/tweaks.rb'
require 'paint'

module ProjectFileReader
  # reads    @raw_data
  # fills    @data
  # uses     @DEFAULTS
  # produces @ERRORS
  # has a    @STATUS

  #getters for path_through_document
  #getting path['through']['document']
  def data key = nil
    return @data if key.nil?
    return @data[key] if @data.keys.include? key
    return nil
  end

  ##
  # little read function
  # returns data if read already
  # or does a lookup
  def read(key, data = @data)
    return nil unless key.class == Symbol

    # data has already been read
    logs Paint["KNOWN KEY: #{key}",:cyan] if data[key]
    return data[key]         if data[key]

    logs Paint["reading :#{key}", :green, :bold]

    raw     = @raw_data[key.to_s]
    default = @DEFAULTS[key.to_s]

    # if key is in raw_data walk it trough applying filters
    if raw
      logs "    FOUND RAW #{key}"
      logs "     walking #{key}"
      return data[key]  = walk(raw, [key])
      #fail "#{self.class} DOES NOT KNOW WHAT TO DO WITH #{raw.class}"
    end

    # or the default from the settings
    unless default.nil?
      logs "    FOUND DEFAULT #{key}"
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
    path = path.join('_') if path.class == Array
    path = path.to_s      if path.class == Symbol
    parser = prefix+path
    begin parser = method(parser)
    rescue NameError
      return value
    else
      logs Paint[path, :yellow]
      return parser.call(value)
    end
  end

  def fail_at(*criteria)
    @data[:valid] = false
    criteria.each  {|c|
      @ERRORS.push c unless @ERRORS.include? c
    }
    return nil
  end

end
