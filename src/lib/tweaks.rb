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

def warn (string)
  puts Paint["WARNING: #{string}",:red]
end


def error(msg)
  STDERR.puts("ERROR: #{msg}")
  exit 1
end
