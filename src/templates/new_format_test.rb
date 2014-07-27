#!/usr/bin/env ruby
# encoding: utf-8
require 'pp'
require 'erb'
require 'yaml'


## open given .yml and parse into @data
def open(filename, name = nil)
  event_name     = "test event"
  personal_notes = ""
  manager_name   = "Hendrik"
  default_lang   = "de"
  default_tax    = "0.19"
  if File.exists?(filename)
    engine=ERB.new(File.read(filename),nil,'<>')
    result = engine.result(binding)
    begin
      @raw_data        = YAML::load(result)
    rescue SyntaxError =>error
      puts "can't parse"
      puts error.message
    rescue Psych::BadAlias=>error
      puts error.message
      lines = result.lines.to_a
      lines.each_index {|i| puts "#{i}| #{lines[i]}"} 
    end
    pp @raw_data
  else
    puts "no file"
  end
end

open("new_blank.yml.erb")
