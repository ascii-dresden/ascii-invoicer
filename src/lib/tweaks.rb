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

  def to_euro(rj = -1)
    return self unless self.class == Float
    a,b = sprintf("%0.2f", self.to_s).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    if rj > 0
      "#{a},#{b}€".rjust rj
    else
      "#{a},#{b}€"
    end

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

