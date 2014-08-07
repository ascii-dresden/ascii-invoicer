# encoding: utf-8

$FB = "foobar"
class TrueClass
  def print
    "\e[32m✓\e[0m"
  end
end

class FalseClass
  def print
    "\e[31m✗\e[0m"
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

