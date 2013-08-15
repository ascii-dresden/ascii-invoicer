# encoding: utf-8

# # http://stackoverflow.com/questions/1891429/decorators-in-ruby-migrating-from-python
# module Documenter
#   def document(func_name)   
#     old_method = instance_method(func_name) 
# 
#     define_method(func_name) do |*args|   
#       puts "about to call #{func_name}(#{args.join(', ')})"  
#       old_method.bind(self).call(*args)  
#     end
#   end
# end

require 'git'
require 'logger'

module GitPlumber

  def check_git
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
    @git.log.to_a.reverse.each do |commit|
      table.add_row [
        commit.author.name,
        commit.message,
        commit.date.strftime("%H:%M Uhr — %d.%m.%Y"),
      ]
    end
    puts table
  end

  def git_push()
    @git = Git.open @dirs[:storage], :log => Logger.new(STDOUT)
    out = @git.push()
    puts out if out
  end

  def git_pull()
    @git = Git.open @dirs[:storage], :log => Logger.new(STDOUT)
    out = @git.pull()
    puts out if out
  end

  def git_commit(message)
    @git.commit(message)
  end

  def git_update_path path = @git.dir
    return unless @settings['use_git']
    if File.exists? path
      @git.add path
    else
      @git.remove path, {:recursive => true}
    end

  end

  def git_save message
    puts "GITSAVE\n"
    git_add()
    @git.commit_all "ruby git #commit_all \"#{message}\""
  end

  def git_status
    renamed = git_renamed_files
    exclude = renamed.flatten
    if @git.status.added.length + @git.status.deleted.length + @git.status.untracked.length + @git.status.changed.length == 0
      puts "Nothing Changed"
    end

    git_print_status :added,      exclude
    git_print_status :changed,    exclude
    git_print_status :deleted,    exclude
    git_print_status :untracked,  exclude
    git_print_renamed renamed
  end

  def git_print_status name, exclude
    case name
      when :added     then status = @git.status.added
      when :changed   then status = @git.status.changed
      when :deleted   then status = @git.status.deleted
      when :untracked then status = @git.status.untracked
    end
    status.reject! {|k,v| exclude.include? k }

    puts "#{status.length} #{name.to_s.capitalize}:" if status.length > 0
    status.each do |path, info|
      case info.type
      when "M" then color = :yellow
      when "A" then color = :green
      when "D" then color = :red
      else color = :default
      end
      line = Paint[path, color]
      state = " "
      state = Paint[ "\e[32m✓\e[0m" , :green] if !info.sha_index.nil? and info.sha_index.to_i(16) > 0
      puts "#{state} #{line}"
    end
    puts if status.length > 0
  end

  def git_renamed_files
    repo_shas = {}
    index_shas = {}
    out = ""
    files = []
    @git.lib.diff_index('HEAD').each { |file, data|
      sr = data[:sha_repo]
      si = data[:sha_index]
      repo_shas[sr] = file if sr.to_i(16) > 0
      index_shas[si] = file if si.to_i(16) > 0
      if index_shas.include? sr
        files.push [ repo_shas[sr], index_shas[sr] ]
      end
    }
    return files
  end

  def git_print_renamed files
    puts "#{files.length} Renamed:" if files.length > 0
    width = 0
    files.map {|a,b| width = a.length if a.length > width}
    out = ""
    files.each {|a,b|
      a = a.ljust(width)
      out << Paint[ "\e[32m✓\e[0m" , :green] + " "
      out << Paint[a, :red]
      out << " -> "
      out << Paint[b, :green]
      out << "\n"
    }
    puts out if out.length > 0
  end


end
