# encoding: utf-8

module GitPlumber

  def init_git
    begin
      @git = Git.open @dirs[:storage]
      return true
    rescue
      return false
    end
  end

  def git_log
    table = CliTable.new
    table.borders = false
    @git.log.each do |commit|
      table.add_row [
        commit.author.name,
        commit.message,
        commit.date.strftime("%H:%M %d.%m.%Y"),
      ]
    end
    puts table
  end

  def git_print_status name
    case name
      when :added     then status = @git.status.added
      when :changed   then status = @git.status.changed
      when :deleted   then status = @git.status.deleted
      when :untracked then status = @git.status.untracked
    end
    puts "#{status.length} #{name.to_s.capitalize}:" if status.length > 0
    status.each do |file|
      case file[1].type 
      when "M" then color = :green
      when "A" then color = :blue
      when "D" then color = :red
      else color = :yellow
      end
      puts Paint[file[0], color]
    end
    puts
  end

  def git_add
    @git.add @git.dir
    @git.status.deleted.each { |path| @git.remove path[0] if File.exists? path[0]}
  end
  def git_save message
    puts "GITSAVE\n"
    git_add()
    @git.commit_all "ruby git #commit_all \"#{message}\""
  end

  def git_status
    git_print_status :added     
    git_print_status :changed   
    git_print_status :deleted   
    git_print_status :untracked 
  end

end
