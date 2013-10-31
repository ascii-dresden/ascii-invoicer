#!/bin/env ruby
# encoding: utf-8
require "./textboxes.rb"
require "pp"


table= TableBox.new
table.borders = true
table.add_row [nil,3,4,5]
table.add_row [2,3,4,5]
table.add_row [3,3,5,605.0]
table.add_row [Paint["hello world", :green],nil,nil,nil]
table.add_row 27
#table.add_row ['1','zwei','drei']
#table.add_row ['eins','zwei','drei']
table.add_row ["",Paint['eins',:red],"hello\n world",'drei']
#table.add_row ['eins','zwei','drei','vier']
#table.add_row ['eins','zwei','drei']
table.add_row(table.column_widths.map{|w| "X"*w})

#pp table.rows

table.padding_horizontal = 1
table.cell_borders = true
table.add_row [1,2,3,4]
table.set_alignment(0, :r)
table.set_alignment(1, :r)
table.set_alignment(2, :r)
table.set_alignment(3, :r)
#table.footer = "hello\n world"
pp table.rows
puts table
