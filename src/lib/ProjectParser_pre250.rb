# encoding: utf-8
require File.join File.dirname(__FILE__) + '/parsers/parsers_pre250.rb'

class InvoiceParser_pre250 < InvoiceParserBase
  include InvoiceParsers_pre250
end
