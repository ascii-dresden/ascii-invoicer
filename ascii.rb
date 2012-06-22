#!/usr/bin/ruby
# encoding: utf-8

require 'yaml'

class Invoicer

  attr_reader :invoiceaw_data, :md, :products, :template_offer, :template_invoice
  
  def initialize
    @defaults = {:tax => 0.19}
  end


  # Läd übergebene
  def load_data(datafile)
    if File.exists?(datafile)
      file = File.open(datafile)
      @raw_data = YAML::load(file)
    end
  end


  # Läd latex Vorlagen
  def load_templates(hash)
    @template_offer = File.open(hash[:offer]).read if File.exists?(hash[:offer])
    @template_invoice = File.open(hash[:invoice]).read if File.exists?(hash[:invoice])
  end


  # Verarbeitet die Produktliste
  def mine_data (type)
    mine_products type
    @md = @raw_data

    # datum
    date  =  @raw_data['date'].split('.')
    today = Time.now

    # anrede
    if @md['client'].downcase.include? 'herr'
      @md['client'] = "Sehr geehrter " + @md['client']
    else
      @md['client'] = "Sehr geehrte " + @md['client']
    end

    @md['address'] = @raw_data['address'].each_line.map{|l| l.gsub(/[\n]/, " \\newline " )}.join


    # Angebotsnummer
    if @md['manumber'].nil?
      @md['offer-number'] =  ['A', today.year , "%02d" % today.month , "%02d" % today.mday, '-', @md['anumber']].join 
    else
      @md['offer-number'] = @md['manumber']
    end

    @md['betreuung'] = @raw_data['hours']['salary'] * @raw_data['hours']['time']
    @md['netto'] = 0 ; @products.each{|p| @md['netto'] += p['sum']}
    @md['tax'] = @defaults[:tax] * @md['netto']
    @md['brutto'] = @md['netto'] + @md['tax']
    @md['summe'] =  @md['betreuung'] + @md['brutto']

    # Werte in Preise Umwandeln
    @md['netto'] = @md['netto'].euro
    @md['summe'] = @md['summe'].euro
    @md['tax'] = @md['tax'].euro

    # Betreuung
    if @md['betreuung'] > 0
      @md['betreuung'] = @md['betreuung'].euro
      betreuung_line = [ @products.length ," & Betreuung (Stunden)& " , @raw_data['hours']['time'].to_s , " & " , @raw_data['hours']['salary'].euro, " & " , @md['betreuung'] ].join + " \\\\\\ \n"
      #betreuung_line = [ @products.length ," & Service (hour)& " , @raw_data['hours']['time'].to_s , " & " , @raw_data['hours']['salary'].euro, " & " , @md['betreuung'] ].join + " \\\\\\ \n"
    else
      betreuung_line = ''
    end

    @md[''] = product_table + betreuung_line

    # optional Veranstaltungsname
    @md['event'] = @raw_data['event'].nil? ? nil : @raw_data['event'] 

    # optional Rechnungsnummer
    @md['invoice-number'] = @raw_data['rnumber'].nil? ? '' : 'R'+date[2]+ "-%04d" % @raw_data['rnumber']

  end
  
  # Verarbeitet die Produktliste
  def mine_products(type)
    @products = []
    @nproducts = {}
    @raw_data['products'].each { |name, s|

      # alles verkauft
      if s['returned'].nil? and s['sold'].nil? or type == :offer
        sold = s['amount'] 
      # was zurueck bekommen
      elsif s['sold'].nil?
        sold = s['amount'] - s['returned'] 
      # fester wert verkauft
      elsif s['returned'].nil?
        sold = s['sold'] 
      else
        puts name + ' contains both sold and returned'
        exit
      end
     
      p = {}
      p['name'] = name
      p['sold'] = sold
      p['price'] = s['price']
      p['sum'] = (sold * p['price'])

      @products.push p 
      @nproducts[name] = p 
    }
  end

  def product_table
    table = ""
    @products.each_with_index do |p, i|
      table += [i.to_s , " & " , p['name'].to_s , " & " , p['sold'].to_s , " & " , p['price'].euro, " & " , p['sum'].euro].join + " \\\\\\ \n"
    end
    table
  end


  def fill type
    mine_data type
    case type
      when :invoice
        template = @template_invoice
      when :offer
        template = @template_offer
    end
    filled = template.each_line.map { |line| 
      @md.keys.each{ |key|
       line = line.gsub('$' + key + '$',
        @md[key].to_s)
      }
      line
    }
    puts filled 
  end
end


#euro wert Ausgabe für normale Zahlen
class Object
  def euro
    rounded = (self*100)/100.0
    a,b = sprintf("%0.2f", rounded).split('.')
    a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    "#{a},#{b}€"
  end
end


## Initialisierung des Programms

invoice = Invoicer.new
invoice.load_templates :invoice => 'latex/ascii-rechnung.tex', :offer => 'latex/ascii-angebot.tex'
#invoice.load_templates :invoice => 'latex/ascii-rechnung-en.tex', :offer => 'latex/ascii-angebot-en.tex'


unless ARGV[1].nil? 
  if File.exists? ARGV[0]
    invoice.load_data ARGV[0]
  end

  case ARGV[1]
    when 'r' 
      invoice.fill :invoice
    when 'a'
      invoice.fill :offer
  end
end
