require 'date'

#interface
class PlumberProject

  def initialize path
    open path
  end

  def open path
    @path = path
  end

  def path
    @path
  end

  def name
    File.basename @path, ".yml"
  end

  def date
    return Date.today

  end
end
