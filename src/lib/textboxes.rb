# encoding: utf-8
require 'paint'

class TextBox
  attr_writer :borders, :cell_borders, :width,
    :top, :bottom, :splitter, :border_horizontal, :border_vertical,
    :column_alignments,
    :padding_horizontal, :padding_vertical,
    :header, :footer

  attr_reader :borders, :width, :column_widths, :column_count, :content_width,
    :padding_horizontal, :row_heights, :rows

  # TODO take :box or :table or :aligning for matching defaults
  def initialize()
    @top               = [ "┌", "┐", "┬" ]
    @bottom            = [ "└", "┘", "┴" ]
    @splitter          = [ "├", "┤", "┼" ]
    @border_vertical   = "│"
    @border_horizontal = "─"

    @rows              = []
    @row_heights       = []
    @column_widths     = []
    @column_alignments = []
    @column_count      = 0
    @content_width     = 0

    @header             = ""
    @footer             = ""

    @borders            = false
    @cell_borders       = false
    @padding_horizontal = 1
    #@padding_vertical   = 0

  end

  ## setter for header line
  def header= line
    @content_width = max @content_width, Paint.unpaint(line).length
    @header = line
  end

  ## setter for footer line
  def footer= line
    @content_width = max @content_width, Paint.unpaint(line).length
    @footer = line
  end

  # set the alignment of a column
  def set_alignment index, alignment
    @column_alignments[index] = alignment
  end


  # takes a string → wrapper for single column row
  def add_line line
    add_row [line]
  end

  # takes an array of columns
  def add_row row
    height = 0
    width = 0
    row.each_index { |i|
      row[i] = "" if row[i] == false
      cell = row[i]
      a = :l
      a = :r if cell.class == Float or cell.class == Fixnum
      cell = cell.to_s

      height = max height, cell.lines.to_a.length

      @column_widths.push 0     unless i < @column_widths.length
      @column_alignments.push a unless i < @column_alignments.length
      @column_widths[i] = max @column_widths[i], Paint.unpaint(cell).length
    }
    @row_heights << height
    @column_count = max @column_count, row.length
    @column_widths.each {|w| width += w}
    @content_width = max @content_width, width
    @rows.push row
  end


  def build_header
    string = ""
    string << build_row(@header)
    string << build_border(@splitter) if @cell_borders
    return string
  end

  def width
    width = @content_width + (@column_count  ) * @padding_horizontal * 2 
    width += @column_count -1  if @cell_borders
    width -= 1 if @padding_horizontal > 0
    return width
  end

  def build_border devider
    string = devider[0] + @border_horizontal * ( width() +  @padding_horizontal  ) + devider[1]
    add_vertical_borders(string , devider[2]) if @cell_borders
    return string
  end

  def align_row row
    cells = []
    row.each_index {|i|
      column = row[i].to_s
      case @column_alignments[i]
      when :c
        cells.push column.center @column_widths[i]
      when :l
        cells.push column.ljust  @column_widths[i]
      when :r
        cells.push column.rjust  @column_widths[i]
      else 
        cells.push column.ljust  @column_widths[i]
      end
    }
    return cells
  end

  def build_row(row)
    padding = " " * (@padding_horizontal)
    inpadding = padding+padding 
    inpadding = padding+"#"+padding if @cell_borders

    if row.class == Array
      row = row.each.to_a # copy
    elsif row.class == String
      row = [row]
    end
    row = align_row row

    lines = []
    line_count = 1
    row.each { |cell| line_count = max line_count, cell.lines.to_a.length }
    line_count.times { |i| lines[i] =  row.map { |cell| c = cell.lines.to_a[i].to_s.chomp } }

    string = ""
    lines.each { |line|
      lstring = ""
      line = align_row line
      lstring << @border_vertical << padding if @borders
      lstring << line.join(inpadding).ljust(width())
      lstring << @border_vertical if @borders
      lstring <<  "\n"
      add_vertical_borders(lstring , @border_vertical) if @cell_borders
      string << lstring
    }
    string
  end

  def add_vertical_borders(line, devider = @splitter)
    widths = @column_widths.each.to_a
    widths.pop
    p = 0 #@padding_horizontal 
    widths.each { |w|
      p = p + w + @padding_horizontal*2 + 1 
      line[p] = devider if line[p]
    }
    return line
  end

  def build_table
    br     = "\n"
    string = ""

    #top
    string << build_border(@top) << br if @borders
    string << build_row(@header)<< br if @header.length > 0
    string << build_border(@splitter) << br if @borders and @header.length > 0

    rows.each_index{ |i|
      row = rows[i]
        string << build_row(row)

        if @cell_borders
          string << (build_border(@splitter)) << br unless i == rows.length - 1
        end
    }

    #bottom
    string << build_border(@splitter) << br if @borders and @footer.length > 0
    string << build_row(@footer)     << br if @footer.length > 0
    string << build_border(@bottom)         if @borders


    return string
  end

  def to_s
    build_table()
  end

  def max(a,b)
    return a if a>b
    return b
  end





end
