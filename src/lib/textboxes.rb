# encoding: utf-8
require 'paint'

class TableBox
  attr_writer :borders, :cell_borders, :width,
    :top, :bottom, :splitter, :border_horizontal, :border_vertical,
    :column_alignments,
    :padding_horizontal, :padding_vertical,
    :title, :footer

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

    @title             = ""
    @footer             = ""

    @borders            = false
    @cell_borders       = false
    @padding_horizontal = 1
    #@padding_vertical   = 0

  end

  ## setter for title line
  def title= line
    @content_width = max @content_width, Paint.unpaint(line).length
    @title = line
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

  # takes an array of columns
  def add_row row
    row = [row] unless row.class == Array

    row.each_index { |i|
      row[i] = "" unless row[i]
      cell = row[i]

      a = :l
      a = :r if cell.class == Float or cell.class == Fixnum
      @column_alignments.push a unless i < @column_alignments.length

      cell = cell.to_s

      @column_widths << 0     unless i < @column_widths.length
      @column_widths[i] = max(@column_widths[i], Paint.unpaint(cell).length)
    }
    @column_count = max(@column_count, row.length)
    content_width = 0
    @column_widths.each {|w| content_width += w}
    @content_width = max @content_width, content_width
    @rows.push row
  end

  def content_width()
    width = @content_width + (@column_count  ) * @padding_horizontal * 2 
    width += @column_count -1  if @cell_borders
    width -= 1 if @padding_horizontal > 0
    return width
  end

  def align_row row
    cells = []
    row.each_index {|i|
      column = row[i].to_s
      case @column_alignments[i]
      when :c then cells.push column.center @column_widths[i]
      when :l then cells.push column.ljust  @column_widths[i]
      when :r then cells.push column.rjust  @column_widths[i]
      else cells.push column.ljust  @column_widths[i]
      end
    }
    return cells
  end








  def render_border devider
    string = devider[0] + @border_horizontal * ( content_width() +  @padding_horizontal  ) + devider[1]
    render_vertical_border(string , devider[2]) if @cell_borders
    return string
  end

  def render_row(row)
    padding = " " * (@padding_horizontal)
    inpadding = padding+padding 
    inpadding = padding+@border_vertical+padding if @cell_borders


    #fill up the shorter rows
    (@column_count - row.length).times { row << nil }

    row = align_row row

    lines = []
    line_count = 1
    row.each { |cell| line_count = max line_count, cell.lines.to_a.length }
    line_count.times { |i| lines[i] =  row.map { |cell| c = cell.lines.to_a[i].to_s.chomp } }

    string = ""
    lines.each { |line|
      line = align_row line
      line = paint_ljust(line.join(inpadding),content_width())
      #line = line.join(inpadding).ljust(content_width())

      string << @border_vertical << padding if @borders
      string << line
      string << @border_vertical if @borders
      string <<  "\n"
    }
    string
  end

  # fix for ljust in combination with paint
  def paint_ljust(string, width, padstr= " ")
    diff = width - Paint.unpaint(string).length
    return string + (padstr * diff) if diff > 0
    return string
  end

  def render_table
    br     = "\n"
    string = ""

    #top
    string << render_border(@top) << br if @borders
    string << render_row(@title)<< br if @title.length > 0
    string << render_border(@splitter) << br if @borders and @title.length > 0

    rows.each_index{ |i|
      row = rows[i]
        string << render_row(row)

        if @cell_borders
          string << (render_border(@splitter)) << br unless i == rows.length - 1
        end
    }

    #bottom
    string << render_border(@splitter) << br if @borders and @footer.length > 0
    string << render_row(@footer)     << br if @footer.length > 0
    string << render_border(@bottom)         if @borders


    return string
  end

  def render_vertical_border(line, devider = @splitter)
    widths = @column_widths.each.to_a
    widths.pop
    p = 0 #@padding_horizontal 
    widths.each { |w|
      p = p + w + @padding_horizontal*2 + 1 
      line[p] = devider if line[p]
    }
    return line
  end


  def to_s
    render_table()
  end

  def max(a,b)
    return a if a>b
    return b
  end





end
