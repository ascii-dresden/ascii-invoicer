# encoding: utf-8
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
  STDERR.puts(msg)
  exit 1
end

