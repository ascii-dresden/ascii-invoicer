# -*- encoding: utf-8 -*-
require 'rubygems' unless defined? Gem
require File.dirname(__FILE__) + "/lib/ascii_invoicer/version"

Gem::Specification.new do |s|
  s.name        = "ascii_invoicer"
  s.version     = AsciiInvoicer::VERSION
  s.authors     = ["Hendrik Sollich"]
  s.email       = "hendrik@hoodie.de"
  s.homepage    = "https://github.com/ascii-dresden/ascii-invoicer"
  s.summary     = "ascii-invoicer"
  s.description = "
  A commandline project management tool.
  It manages future and past projects, can create invoice documents, csv and ical overviews.
  All from the commandline, syncs via git.
  "
  s.required_ruby_version     = '>= 2.1'
  s.files =
    Dir.glob('lib/*') +
    Dir.glob('lib/*/*') +
    Dir.glob('bin/*') +
    Dir.glob('settings/*') +
    Dir.glob('templates/*') +
    Dir.glob('repl/*') +
    #Dir.glob('spec/*') +
    Dir.glob('latex/*')
  s.executables << 'ascii'
  #s.extra_rdoc_files = ["README.md", "LICENSE.md"]
  s.license = 'GPL'

  s.add_development_dependency 'rspec',       '~> 3.1'
  s.add_development_dependency 'rspec-core',  '~> 3.1'
  s.add_development_dependency 'rake',        '~> 10'
  s.add_runtime_dependency     'git',         '~> 1.2' ,    '>= 1.2.8'
  s.add_runtime_dependency     'thor',        '~> 0.19'
  s.add_runtime_dependency     'icalendar',   '~> 2.1',     '>= 2.1.1'
  s.add_runtime_dependency     'textboxes',   '~> 0.0',     '>= 0.0.1'
  s.add_runtime_dependency     'money',       '~> 6.5.1'
  s.add_runtime_dependency     'hash-graft',  '~> 0.9',     '>= 0.9.0'
  s.add_runtime_dependency     'luigi',       '~> 1.1',     '>= 1.1.0'
  s.add_runtime_dependency     'paint',       '~> 1.0',     '>= 1.0.0'
  s.add_runtime_dependency     'hashr',       '~> 0.0.22',  '>= 0.0.22'
  s.add_runtime_dependency     'repl',        '~> 1.0',     '>= 1.0.0'

end
