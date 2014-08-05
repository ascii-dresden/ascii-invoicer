# encoding: utf-8

class HashTransform
  attr_reader :original_hash, :new_hash
  attr_writer :rules

  def initialize(hash = {})
    @original_hash = hash[:original_hash]
    @original_hash ||= {}
    @new_hash = {}
    @rules = hash[:rules]
    @rules ||= []
  end

  def transform
    @new_hash = @original_hash
    @rules.each {|rule|
      @new_hash.set(rule[:new],  @original_hash.get(rule[:old]))
    }
    return @new_hash
  end

end

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

  def get path, delimiter = ?/, data = self
    path = path.split(delimiter)if [String, Symbol].include? path.class
    return nil unless path.class == Array
    while key = path.shift
       if data.class == Hash and not data[key].nil?
         data = data[key]
         return data if path.length == 0

       elsif data.class == Hash and not data[key.to_sym].nil?
         data = data[key.to_sym]
         return data if path.length == 0

       elsif data.class == Array and key =~ /^\d*$/ and not data[key.to_i].nil?
         data = data[key.to_i]
         return data if path.length == 0

       else
         return data[key]
         return nil
       end
    end
  end

  def set path, value, delimiter = ?/, symbols = false
    data = self
    path = path[1..-1] if path.class == String and path[0] == delimiter
    path = path.to_s.split(delimiter) if [String, Symbol].include? path.class
    return nil unless path.class == Array
    while key = path.pop
      if key =~ /^\d*$/
        v = value
        value = []
        value[key.to_i] = v
      else
        key = key.to_sym if symbols
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
