# encoding: utf-8
require './lib/object.rb'
class Invoicer

  attr_reader :invoiceaw_data, :data, :products, :template_offer, :template_invoice
  attr_writer :type, :project_name
  
  def initialize
    @defaults = {:tax => 0.19}
  end


  ## open given .yml and parse into @data
  def load_data(datafile)
    if File.exists?(datafile)
      file = File.open(datafile)
      @data = YAML::load(file)
    end
  end


  # Läd latex Vorlagen
  def load_templates(hash)
    @template_offer = File.open(hash[:offer]).read if File.exists?(hash[:offer])
    @template_invoice = File.open(hash[:invoice]).read if File.exists?(hash[:invoice])
  end


  # Verarbeitet die Produktliste
  def mine_data

    # datum
    date  =  @data['date'].split('.')
    @data['raw_date'] = Time.new date[2], date[1], date[0]
    today = Time.now

    # anrede
    @data['raw_client_raw'] = @data['client']
    if @data['client'].downcase.include? 'herr'
      @data['client'] = "Sehr geehrter " + @data['client']
    else
      @data['client'] = "Sehr geehrte " + @data['client']
    end

    @data['raw_address'] = @data['address']
    @data['address'] = @data['raw_address'].each_line.map{|l| l.gsub(/[\n]/, " \\newline " )}.join


    # Angebotsnummer
    if @data['manumber'].nil?
      @data['offer-number'] =  ['A', today.year , "%02d" % today.month , "%02d" % today.mday, '-', @data['anumber']].join 
    else
      @data['offer-number'] = @data['manumber']
    end

    @data['betreuung'] = @data['hours']['salary'] * @data['hours']['time']
    @data['netto']     = 0 ; @products.each{|p| @data['netto'] += p['sum']}
    @data['tax']       = @defaults[:tax] * @data['netto']
    @data['brutto']    = @data['netto'] + @data['tax']
    @data['summe']     = @data['betreuung'] + @data['brutto']

    # Werte in Preise Umwandeln
    @data['netto'] = @data['netto'].euro
    @data['summe'] = @data['summe'].euro
    @data['tax']   = @data['tax'].euro

    # Betreuung
    if @data['betreuung'] > 0
      @data['betreuung'] = @data['betreuung'].euro
      betreuung_line = [ @products.length ," & Betreuung (Stunden)& " , @data['hours']['time'].to_s , " & " , @data['hours']['salary'].euro, " & " , @data['betreuung'] ].join + " \\\\\\ \n"
      #betreuung_line = [ @products.length ," & Service (hour)& " , @data['hours']['time'].to_s , " & " , @data['hours']['salary'].euro, " & " , @data['betreuung'] ].join + " \\\\\\ \n"
    else
      betreuung_line = ''
    end

    @data[''] = product_table + betreuung_line

    # optional Veranstaltungsname
    @data['event'] = @data['event'].nil? ? nil : @data['event'] 

    # optional Rechnungsnummer
    @data['invoice-number'] = @data['rnumber'].nil? ? '' : 'R'+date[2]+ "-%04d" % @data['rnumber']

  end
  
  # Verarbeitet die Produktliste
  def mine_products
    @products = []
    @data['products'].each { |name, s|

      # alles verkauft
      if s['returned'].nil? and s['sold'].nil? or @type == :offer
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
    }
  end

  def product_table
    table = ""
    @products.each_with_index do |p, i|
      table += [i.to_s , " & " , p['name'].to_s , " & " , p['sold'].to_s , " & " , p['price'].euro, " & " , p['sum'].euro].join + " \\\\\\ \n"
    end
    table
  end

  def is_valid
    puts "IMPLEMENT VALIDITY CHECKS !!"
    @type == :invoice || :offer and
    not @name.nil? and @name != ""
  end

  ## produces an appropriate filename for each type
  def filename
    ext = '.tex'
    case @type
      when :invoice
        name = @data['invoice-number']+ext
      when :offer
        name = @data['']+ext
    end
  end

  ## fills the template with minded data
  def create
    mine_products
    mine_data
    case @type
      when :invoice
        template = @template_invoice
      when :offer
        template = @template_offer
    end

    filled = template.each_line.map { |line| 
      @data.keys.each{ |key|
       line = line.gsub('$' + key + '$',
        @data[key].to_s)
      }
      line
    }
  end

  def dump
    @data
  end
end
