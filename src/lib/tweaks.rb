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

class Object
  def ceil_up
    return self unless self.class == Float
    n = self
    n = n*100
    n = n.round().to_f()
    n = n/100
    return n
  end

end

def do_ask
  gets.strip
rescue Interrupt
  puts
  exit
end

def error(msg)
  STDERR.puts("ERROR: #{msg}")
  exit 1
end
