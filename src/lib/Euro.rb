# encoding: utf-8
class Euro

  def initialize value
    @value = value.to_f
    return self
  end

  def method_missing *args, &blk
    v = @value.send *args, &blk
    if v.class == Float or v.class == Fixnum 
      return Euro.new v
    else return v
    end
  end

  def == v
    return v.to_f == @value unless v.class == FalseClass or v.class == TrueClass
    return false
  end

  def + v
    return (@value + v.to_f).to_euro
  end

  def to_f
    @value.ceil_up
  end

  def to_euro
    self
  end

  def to_s
    return @value unless @value.class == Float
    a,b = sprintf("%0.2f", @value.to_s).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    "#{a},#{b}€"
  end

end

module EuroConversion
  def to_euro 
    Euro.new self
  end
end

class Fixnum
  include EuroConversion
end

class Float
  def ceil_up
    return self unless self.class == Float
    n = self
    n = n*100
    n = n.round().to_f()
    n = n/100
    return n
  end
  include EuroConversion
end
