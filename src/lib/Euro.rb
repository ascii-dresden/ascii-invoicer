# encoding: utf-8
class Euro

  def initialize value
    @value = value.rationalize
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
    return (@value + v.rationalize).to_euro
  end

  def to_f
    @value.ceil_up
  end

  def to_euro
    self
  end

  def to_s
    value = @value.to_f
    a,b = sprintf("%0.2f", value.to_s).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    "#{a},#{b}€"
  end

  #def ceil_up
  #  return self unless self.class == Float
  #  n = self
  #  n = n*100
  #  n = n.round().to_f()
  #  n = n/100
  #  return n
  #end

end

module EuroConversion
  def to_euro 
    Euro.new self
  end
end

class Fixnum
  include EuroConversion
end

class Rational
  include EuroConversion
end

class Float
  include EuroConversion
end
