#!/bin/env ruby
# encoding: utf-8
require "./textboxes.rb"


table= TextBox.new
table.borders = true
table.add_row [2,3,4,5]
table.add_row [3,3,5,605.0]
table.add_row ['1','zwei','drei']
table.add_row ['eins','zwei','drei']
table.add_row ['eins',nil,'drei']
table.add_row ['eins','zwei','drei','vier']
table.add_row ['eins','zwei','drei']
table.add_row(table.column_widths.map{|w| "X"*w})

table.padding_horizontal = 1
table.cell_borders = true
table.add_row [1,2,3,4]
table.set_alignment(0, :c)
table.set_alignment(1, :c)
table.set_alignment(2, :c)
table.set_alignment(3, :c)
puts table


puts table.content_width
puts table.column_count
puts table.padding_horizontal
puts table.width()
