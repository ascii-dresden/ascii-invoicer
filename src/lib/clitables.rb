# encoding: utf-8
class CliTable < TextBox
  #TODO colspan
  #TODO rowspan
  
  attr_writer :borders, :column_alignments

  def initialize()
    super()
    @borders = true
    @rows = []
    @column_widths = []
    @column_alignments = []
  end

  def add_row row
    row.each_index { |i|
      row[i] = "" if row[i] == false
      column = row[i]
      @column_widths.push 0      unless i < @column_widths.length
      @column_alignments.push :l unless i < @column_alignments.length
      @column_widths[i] = max @column_widths[i], column.length
    }

    @rows.push row
  end

  def vborder 
    pad = " " * @padding_horizontal
    return pad * 2 unless @borders
    return pad + @border_vertical + pad
  end

  def align_rows
    aligned_rows = []
    @rows.each { |row| row = aligned_rows.push(align_row(row)) }
    return aligned_rows
  end

  def align_row row
    columns = []
    row.each_index {|i|
      column = row[i]
      case @column_alignments[i]
      when :c
        columns.push column.center @column_widths[i]
      when :l
        columns.push column.ljust  @column_widths[i]
      when :r
        columns.push column.rjust  @column_widths[i]
      else 
        columns.push column.ljust  @column_widths[i]
      end
    }
    return columns
  end

  def join_columns columns
    string = ""
    string << columns.join(vborder)
    @width = max @width, string.length
    return string
  end

  def set_alignment index, alignment
    @column_alignments[index] = alignment
  end

  def build_splitter(cross, index = -1)
    return "" unless @borders
    string = super(cross)
    return string if index == -1
    @column_widths.each_index {|i|
      w = @column_widths[i]
      string[w+3*@padding_horizontal] = @splitter[2] unless i == (@column_widths.length - 1 )
    }
    return string 
  end

  def build
    rows = align_rows()
    rows.map! {|r| r = join_columns r}

    @width = max @width, @header.length
    @padded_width = @width + @padding_horizontal * 2
    string = ""

    #top
    string << build_splitter(@top)
    string << build_header() if @header.length > 0
    string << vpadding


    rows.each_index{ |i|
      row = rows[i]
      string << build_line(row)
      string << build_splitter(@splitter,i) unless i == rows.length - 1
    }

    #bottom
    string << vpadding
    string << build_footer() if @footer.length > 0
    string << build_splitter(@bottom)

    return string
  end

end

