# encoding: utf-8
class TextBox
  attr_writer :header, :footer, :padding_horizontal, :padding_vertical, :top, :bottom, :splitter, :border_vertical, :border_horizontal, :borders

  def initialize()
    @top               = [ "┌", "┐", "┬" ]
    @splitter          = [ "├", "┤", "┼" ]
    @bottom            = [ "└", "┘", "┴" ]

    @lines             = []
    @border_vertical   = "│"
    @border_horizontal = "─"
    @header = ""
    @footer = ""
    @borders = true

    @width = 0
    @padding_horizontal = 1
    @padding_vertical   = 0
  end

  def add_line line
    @width = max @width, line.length
    @lines.push line
  end

  def vpadding
    return (@border_vertical + " "*@padded_width + @border_vertical + "\n") * @padding_vertical
  end

  def hpadding
    return " " * @padding_horizontal
  end

  def build_header
    string = ""
    string << build_line(@header)
    string << build_splitter(@splitter)
    return string
  end

  def build_footer
    string = ""
    string << build_splitter(@splitter)
    string << build_line(@footer)
    return string
  end

  def build_splitter(cross)
    string = ""
    if cross[0]
      string << cross[0]
      string << @border_horizontal * @padded_width
      string << cross[1] if cross[1]
      string << "\n"
    end
    return string
  end

  def build_line(line)
    string = ""
    string << @border_vertical if @borders
    string << hpadding
    string << line.ljust(@width)
    string << hpadding
    string << @border_vertical if @borders
    string << "\n"
    return string
  end

  def build
    @width = max @width, @header.length
    @padded_width = @width + @padding_horizontal * 2
    string = ""

    #top
    string << build_splitter(@top)
    string << build_header() if @header.length > 0
    string << vpadding

    @lines.each{ |line| string << build_line(line) }

    #bottom
    string << vpadding
    string << build_footer() if @footer.length > 0
    string << build_splitter(@bottom)

    return string + "\n"
  end

  def to_s
    build
  end

  def max(a,b)
    return a if a>b
    return b
  end


end
