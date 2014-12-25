$FB = "foobar"
class TrueClass
  def print(symbol=?✓)
    "\e[32m#{symbol}\e[0m"
  end
end

class FalseClass
  def print(symbol=?✗)
    "\e[31m#{symbol}\e[0m"
  end
end

class String
  def words
    self.split " "
  end
end

class Date
  def to_s
    self.strftime "%d.%m.%Y"
  end
end

