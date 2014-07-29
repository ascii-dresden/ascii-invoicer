# encoding: utf-8
require File.join File.dirname(__FILE__) + '/parsers/parsers.rb'

class ProjectParser < ProjectParserBase
  include ProjectParsers
end
