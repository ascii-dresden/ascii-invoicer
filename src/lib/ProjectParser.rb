# encoding: utf-8
require File.join File.dirname(__FILE__) + '/parsers/parsers.rb'

class InvoiceParser < InvoiceParserBase
  include InvoiceParsers
end
