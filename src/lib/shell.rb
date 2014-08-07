# encoding: utf-8

module Shell

  def logs(*strings)
    puts strings.join " "
  end

  def debug(*string)
    puts Paint["DEBUG: #{caller.last} #{string}",:yellow, :bold] if $SETTINGS['DEBUG']
  end


  def ppath (path)
    logs Paint["path : #{path.join ?_}",:yellow]
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

  def do_ask
    begin
      gets
    rescue => interrupt
      puts interrupt
      exit
    end
  end

  def yes?(message="Are you sure you wish to continue?")
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
end
