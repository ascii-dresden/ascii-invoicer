# encoding: utf-8

require './lib/tweaks.rb'

class Hash
  def graft a
    a.each { |k,v|
      if self[k].class == Hash and a[k].class == Hash
        self[k].graft a[k]

      elsif self[k].class == Array and a[k].class == Array
        self[k].graft a[k]

      else
        self[k] = a[k]

      end
    }
    return self
  end

  def get path, data = self, delimiter = ?/
    path = path.split(delimiter)if [String, Symbol].include? path.class
    return nil unless path.class == Array
    while key = path.shift
       if data.class == Hash and not data[key].nil?
         data = data[key]
         return data[key] if path.length == 0

       elsif data.class == Hash and not data[key.to_sym].nil?
         data = data[key.to_sym]
         return data if path.length == 0

       elsif data.class == Array and key =~ /^\d*$/ and not data[key.to_i].nil?
         data = data[key.to_i]
         return data if path.length == 0

       else
         return nil
       end
    end
  end

  def set path, value, data = self, delimiter = ?/
    path = path.split(delimiter) if [String, Symbol].include? path.class
    return nil unless path.class == Array
    while key = path.pop
      if key =~ /^\d*$/
        v = value
        value = []
        value[key.to_i] = v
      else
        value = {key => value}
      end
    end
    data.graft value
  end
end

class Array
  def graft a
    a.each_index{|i| self[i] = a[i] unless a[i].nil? }
  end
end

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

  def apply_filter path, value
    path = path.join('_') if path.class == Array
    prefix = "filter_"
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
