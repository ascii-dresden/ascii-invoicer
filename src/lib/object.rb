# encoding: utf-8

#euro wert Ausgabe für normale Zahlen
class Object
  def euro
    rounded = (self*100)/100.0
    a,b = sprintf("%0.2f", rounded).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    "#{a},#{b}€"
  end
end
