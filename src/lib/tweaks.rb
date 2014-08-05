# encoding: utf-8

$FB = "foobar"
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

class String
  def words
    self.split " "
  end
end

def logs(*strings)
  puts *strings
end

def debug(*string)
  puts Paint["DEBUG: #{caller.last} #{string}",:yellow, :bold] if $SETTINGS['DEBUG']
end


def ppath (path)
  #logs Paint["path : #{path.join ?_}",:yellow]
end

def info (string)
  puts Paint["INFO: #{string}",:blue, :bold] if $SETTINGS['DEBUG']
end


def warn (string)
  puts Paint["WARNING: #{ caller[0] } #{string}",:red]
  #puts Paint["WARNING: #{string}",:red]
end


def error(msg)
  STDERR.puts("ERROR: #{msg}")
  exit 1
end
