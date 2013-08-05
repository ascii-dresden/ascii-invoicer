# encoding: utf-8
class TrueClass
  def to_s
    "\e[32m✓\e[0m"
  end
end

class FalseClass
  def to_s
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

def sure?(message="Are you sure you wish to continue?")
  display("#{message} (y/N)? ", false)
  do_ask.downcase == 'y'
end

def display(msg, newline=true)
  if newline
    puts(msg)
  else
    print(msg)
    STDOUT.flush
  end
end

def error(msg)
  STDERR.puts("ERROR: #{msg}")
  exit 1
end

