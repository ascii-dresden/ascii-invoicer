#!/bin/env ruby
# encoding: utf-8
require "./textboxes.rb"
require "pp"

table= TableBox.new
rows = []
rows << [nil,3,4,5]
rows << [2,3,4,5]
rows << [3,3,5,605.0]
rows << [Paint["hello world", :green],nil,nil,nil]
rows << 27
rows << ['1','zwei','drei']
rows << ['eins','zwei','drei']
rows << ["",Paint['eins',:red],"hello\nworld",'drei']
rows << ['eins','zwei','drei','vier','fünf']
rows << ['eins','zwei','drei']
table.add_row ['eins','zwei','drei'], :red

#pp table.rows

table.add_rows rows
table.add_row ['eins','zwei','drei'], :yellow
table.add_rows [
  [1,2,3,4,5],
  [2,3,4,5,6],
  [3,4,5,6,7],
]

table.style[:padding_horizontal] = 1
table.style[:border]             = true
table.style[:column_borders]     = false
table.style[:row_borders]        = false


table.set_alignments(:r, :r, :c, :l, :r)

#table.title= Paint["test table",:red]
table.title = "test table"
#table.footer = "test table"
table.set_headings ['eins','zwei','drei','vier','fünf']

table.add_row(table.column_widths.map{|w| "X"*w})
puts table
#pp table.rows

