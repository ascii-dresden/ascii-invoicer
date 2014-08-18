# encoding: utf-8
require 'paint'

class TableBox

  attr_writer :top, :bottom, :splitter,
    :padding_horizontal,
    :title, :footer

  attr :style, :row_colors, 
    :column_alignments

  attr_reader :width, :column_widths, :column_count, :content_width,
    :padding_horizontal, :rows

## TODO take :box or :table or :aligning for matching defaults
## TODO style[:column_borders,:row_borders]
  def initialize(hash = {})

    @borders          = {}
    @borders[:top]    = [ "┌", "┐", "┬"]
    @borders[:middle] = [ "├", "┤", "┼"]
    @borders[:bottom] = [ "└", "┘", "┴"]
    @borders[:column] = "│"
    @borders[:row]    = "─"

    @rows              = []
    @row_colors        = [] # each row can have an array of colors see: https://github.com/janlelis/paint/
    @row_heights       = []
    @column_widths     = []
    @column_alignments = []
    @column_count      = 0
    @content_width     = 0

    @title             = nil
    @footer            = nil

    @style                      = {}
    @style[:border]             = false
    @style[:row_borders]        = false
    @style[:column_borders]     = false
    @style[:padding_horizontal] = 1
    #@padding_vertical          = 0

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
  def set_alignments *aligns
    aligns.each_index {|index| @column_alignments[index] = aligns[index] }
  end

  def set_alignment index, alignment
    @column_alignments[index] = alignment
  end

  # takes an array of columns
  def add_rows rows
    rows.each {|row| add_row row}
  end

  def set_headings row
    @headings = prepare_row row
  end

  def prepare_row row
    row = [row] unless row.class == Array

    row.each_index { |i|
      row[i] = "" unless row[i]
      cell = row[i]

      a = :l
      a = :r if cell.class == Float or cell.class == Fixnum
      @column_alignments.push a unless i < @column_alignments.length

      cell = cell.to_s

      @column_widths << 0     unless i < @column_widths.length
      cell.to_s.lines.each {|line|
        @column_widths[i] = max(@column_widths[i], Paint.unpaint(line).length)
      }
    }
    @column_count = max(@column_count, row.length)
    content_width = 0
    @column_widths.each {|w| content_width += w}
    @content_width = max @content_width, content_width
    return row
  end

  def add_row row, color = []
    @rows.push prepare_row row
    @row_colors.push([color].flatten)
  end

  def content_width()
    width = @content_width + (@column_count  ) * @style[:padding_horizontal] * 2 
    width += @column_count -1  if @style[:column_borders]
    width -= 1 if @style[:padding_horizontal] > 0
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








  def render_column_borders(line, devider = @borders[:column])
    widths = @column_widths.each.to_a
    widths.pop
    p = 0
    p = -1 -@style[:padding_horizontal] if @style[:column_borders] and not @style[:border]
    widths.each { |w|
      p = p + w + @style[:padding_horizontal]*2 + 1 
      line[p] = devider if line[p]
    }
    return line
  end

  def render_row_border orientation 
    devider = @borders[orientation]
    devider[2] = @borders[:row] if orientation == :top and @title
    devider[2] = @borders[:row] if orientation == :bottom and @footer

    if @style[:border]
      string = devider[0] + @borders[:row] * ( content_width() +  @style[:padding_horizontal]  ) + devider[1]
    else
      string = @borders[:row] * ( content_width() - 1 )
    end
    render_column_borders(string , devider[2]) if @style[:column_borders]
    return string
  end

  def render_title (title)
    string = ""
    string << @borders[:column] if @style[:border]
    string << paint_rjust(title,content_width() + @style[:padding_horizontal] )
    string << @borders[:column] if @style[:border]
    string
  end

  def render_row(row, colors = [])
    padding = " " * (@style[:padding_horizontal])
    inpadding = padding+padding 
    inpadding = padding+@borders[:column]+padding if @style[:column_borders]


    #fill up the shorter rows
    (@column_count - row.length).times { row << nil }

    row = align_row row

    lines = []
    line_count = 1
    row.each { |cell| line_count = max line_count, cell.lines.to_a.length }
    line_count.times { |i| lines[i] =  row.map { |cell| c = cell.lines.to_a[i].to_s.chomp } }

    string = ""
    lines.each_index { |i|
      line = align_row lines[i]
      line = paint_ljust(line.join(inpadding),content_width())
      #line = line.join(inpadding).ljust(content_width())

      string << @borders[:column] << padding if @style[:border]
      if colors
        string << Paint[line,*colors]
      else
        string << line
      end
      string << @borders[:column] if @style[:border]
      string <<  "\n"
    }
    string
  end

  def render_table
    br     = "\n"
    string = ""

    #top
    string << render_row_border(:top)    << br if @style[:border]
    string << render_title(@title)                 << br if @title
    string << render_row_border(:middle) << br if @style[:border] and @title

    #headings
    string << render_row(@headings) if @headings
    string << (render_row_border(:middle)) << br if @headings

    rows.each_index{ |i|
      row = rows[i]
      string << render_row(row, @row_colors[i])
      string << (render_row_border(:middle)) << br if i < rows.length - 1 and @style[:row_borders]
    }

    #bottom
    string << render_row_border(:middle) << br if @style[:border] and @footer
    string << render_title(@footer)      << br if @footer
    string << render_row_border(:bottom)       if @style[:border]


    return string
  end
 
  # fix for ljust in combination with paint
  def paint_ljust(string, width, padstr= " ")
    diff = width - Paint.unpaint(string).length
    return string + (padstr * diff) if diff > 0
    return string
  end

  # fix for rjust in combination with paint
  def paint_rjust(string, width, padstr= " ")
    diff = width - Paint.unpaint(string).length
    return (padstr * diff) + string if diff > 0
    return string
  end

  # fix for center in combination with paint
  def paint_rjust(string, width, padstr= " ")
    diff = width - Paint.unpaint(string).length
    return (padstr * (diff/2)) + string + (padstr * (diff.to_f/2).ceil) if diff > 0
    return string
  end


  def to_s
    render_table()
  end

  def max(a,b)
    return a if a>b
    return b
  end

end
