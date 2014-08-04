# encoding: utf-8
class TrueClass
  def print
    "\e[32m✓\e[0m"
  end
end

class FalseClass
  def print
    "\e[31m✗\e[0m"
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

  def set path, value, delimiter = ?/, data = self
    path = path[1..-1] if path.class == String and path[0] == delimiter
    path = path.to_s.split(delimiter) if [String, Symbol].include? path.class
    return nil unless path.class == Array
    while key = path.pop
      if key =~ /^\d*$/
        v = value
        value = []
        value[key.to_i] = v
      else
        key = key[1..-1].to_sym if key[0] == ?:
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

def logs(*strings)
  #puts *strings
end

def debug(*string)
  logs Paint["DEBUG: #{string}",:yellow, :bold]
end


def ppath (path)
  #logs Paint["path : #{path.join ?_}",:yellow]
end

def info (string)
  logs Paint["INFO: #{string}",:blue, :bold]
end


def warn (string)
  puts Paint["WARNING: #{string}",:red]
end


def error(msg)
  STDERR.puts("ERROR: #{msg}")
  exit 1
end
