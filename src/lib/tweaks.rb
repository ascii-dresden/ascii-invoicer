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



class String
  # TODO somebody find my a gem that works and I'll replace this
  def deumlautify
    return self.gsub(/[“”‘’„»«äöüÄÖÜßæÆœŒ€½¼¾©™®]/) do |match|
      case match
      when "“" then '"'
      when "”" then '"'
      when "‘" then "'"
      when "’" then "'"
      when "„" then '"'
      when "»" then ">>"
      when "«" then "<<"
      when "ä" then "ae"
      when "ö" then "oe"
      when "ü" then "ue"
      when "Ä" then "Ae"
      when "Ö" then "Oe"
      when "Ü" then "Ue"
      when "ß" then "ss"
      when "æ" then "ae"
      when "Æ" then "AE"
      when "œ" then "oe"
      when "Œ" then "OE"
      when "€" then "EUR"
      when "½" then "1/2"
      when "¼" then "1/4"
      when "¾" then "3/4"
      when "©" then "(c)"
      when "™" then "(TM)"
      when "®" then "(r)"
      end
    end
  end
end
