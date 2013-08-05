# encoding: utf-8
module InvoiceParsers

  def parse_script_path
    return @settings['script_path']
  end
 
  ##
  def parse_costs(choice = nil)
    return fail_at :costs unless parse :tax
    return fail_at :costs unless parse :products
    return fail_at :costs unless parse :salary_total

    costs = {}
    costs[:costs_invoice] = Euro.new 0.0
    costs[:costs_offer]   = Euro.new 0.0
    costs[:taxes_invoice] = Euro.new 0.0
    costs[:taxes_offer]   = Euro.new 0.0

    @data[:products].each { |name,product|
      costs[:costs_invoice] += product.cost_invoice
      costs[:costs_offer]   += product.cost_offer
      costs[:taxes_invoice] += product.tax_invoice
      costs[:taxes_offer]   += product.tax_offer
    }
    costs[:total_invoice] = (costs[:costs_invoice] + costs[:taxes_invoice]).ceil_up()
    costs[:total_offer]   = (costs[:costs_offer]   + costs[:taxes_offer]).ceil_up()

    return costs[:costs_invoice] if choice == :invoice
    return costs[:costs_offer]   if choice == :offer
    return costs
    false
  end

  def parse_total choice = nil
    return fail_at :total unless choice
    return fail_at "costs_#{choice.to_s}" unless parse :costs
    return fail_at "costs_#{choice.to_s}" unless parse :costs, choice

    return @data[:costs][:total_invoice] if choice == :invoice
    return @data[:costs][:total_offer]   if choice == :offer
    return false
  end

  def parse_taxes choice = nil
    return fail_at :taxes unless choice
    return fail_at "taxes_#{choice.to_s}" unless parse :costs
    return fail_at "taxes_#{choice.to_s}" unless parse :costs, choice

    return @data[:costs][:taxes_invoice] if choice == :invoice
    return @data[:costs][:taxes_offer]   if choice == :offer
    return false
  end

  ##
  def parse_products(choice = nil)
    return fail_at :products unless @raw_data['products']
    return fail_at :products unless parse :tax
    tax_value = @data[:tax]

    products  = {}
    @raw_data['products'].each { |p|
      name = p[0]
      hash = p[1]
      product = InvoiceProduct.new(name, hash, @data[:tax])
      products[name] = product
      return fail_at :products unless product.valid
    }

    return products
  end

  def parse_tex_table(choice = :offer)
    return fail_at :products_tex unless parse :products
    table = ""
    number = 0
    @data[:products].each do |name, p|
      number += 1
      table += "#{number} & #{name} & #{p.amount(choice)} & #{p.price} & #{p.cost(choice)} \\\\\\\\" #TODO put price.to_euro into the InvoiceProduct
    end

    table += [ number+1 ," & Betreuung (Stunden)& " , @data[:time] , " & " , @data[:salary], " & " , @data[:salary_total] ].join + " \\\\\\" if @data[:time] and @data[:time] > 0
    return table
  end

  ##
  def parse_numbers(choice = nil)
    unless @data[:date] or @raw_data['manumber']
      parse :date
      return fail_at :offer_number unless @data[:date]
    end
    year =  @data[:date].year
    numbers ={}

    if choice == :invoice or
        choice == :invoice_short or
        choice == :invoice_long
      # optional invoice_number
      if @raw_data['rnumber'].nil? 
        invoice_number = ''
        return fail_at :invoice_number
      else
        numbers[:invoice_long] = "R#{year}-%03d" % @raw_data['rnumber']
        numbers[:invoice_long] = "R#{year}-%03d" % @raw_data['rnumber']
        numbers[:invoice_short] = "R%03d" % @raw_data['rnumber']
      end
      return numbers[:invoice_long]  if choice == :invoice_long
      return numbers[:invoice_short] if choice == :invoice or choice == :invoice_short
    elsif choice == :offer
      if @raw_data['anumber'].nil?  and @raw_data['manumber'].nil?
        return fail_at :offer_number
      elsif @raw_data['manumber'].nil?
        numbers[:offer] = Date.today.strftime "A%Y%m%d-" + @raw_data['anumber'].to_s
      else
        numbers[:offer] = @raw_data['manumber']
      end
      return numbers[:offer]         if choice == :offer
    end
    return numbers
  end

  ##
  def parse_addressing()
    return fail_at :client unless parse :client
    return @data[:client][:addressing]
  end

  ##
  def parse_client()
    return fail_at :client unless @raw_data['client']

    names = @raw_data['client'].split("\n")
    titles = @raw_data['client'].split("\n")
    titles.pop()
    client = {}
    client[:last_name] = names.last
    client[:titles] = titles.join ' '
    addressing = client_addressing()
    client[:addressing] = [
      addressing,
     client[:titles],
     client[:last_name]
    ].join ' '
    return client
  end

  def client_addressing
    names = @raw_data['client'].split("\n")
    type = names.first.downcase.to_sym
    gender = @gender_matches[type]
    lang = @data[:lang].to_sym
    return @lang_addressing[lang][gender]
  end


  def parse_messages
    return fail_at "message_#{choice.to_s}" unless parse :messages, :parse_simple, :messages
    # TODO muss man ja nicht übertreiben
    @data[:message_invoice_1] = @data[:messages]['invoice'][0]
    @data[:message_invoice_2] = @data[:messages]['invoice'][1]
    @data[:message_offer_1]   = @data[:messages]['offer'][0]
    @data[:message_offer_2]   = @data[:messages]['offer'][1]
  end

  ##
  # returns valid :email or false
  def parse_email()
    return fail_at :email unless @raw_data
    return fail_at :email unless @raw_data['email'] =~ $RFC5322
    return @raw_data['email']
  end

  ##
  # returns :start date or :end date or false
  #   parse_date(:start) # or
  #   parse_date(:end)
  def parse_date(choice = :start)
    #reading date
    return fail_at :date, :date_end unless @raw_data['date']
    begin
      if choice == :start
        return strpdates(@raw_data['date'])[0]
      elsif choice == :end
        return strpdates(@raw_data['date'])[1]
      else return false
      end
    rescue
      return false
    end
  end

  ##
  #   takes :manager or :signatur
  #   return true or false
  def parse_signature(choice = :signature)
    return fail_at :signature,:manager if @raw_data['signature'].nil?
    lines = @raw_data['signature'].split("\n").to_a

    if lines.length > 1
      return lines.last      if choice == :manager
      return lines.join "\n" if choice == :signature
    else
      return lines.first     if choice == :manager
      return @settings["default_signature"] if choice == :signature
    end
    return fail_at :signature,:manager
  end


  ##
  def parse_hours(choice = :hours)
    hours            = {}
    hours[:time]     = @raw_data['hours']['time'].to_f
    hours[:salary]   = @raw_data['hours']['salary'].to_euro
    hours[:caterers] = @raw_data['hours']['caterers']
    hours[:time_each] = 0.0

    hours[:caterers].each { |name,time| hours[:time_each] += time } if hours[:caterers]

    salary_total   = hours[:salary] * hours[:time]
    #salary_total   = Euro.new salary_total

    return fail_at :hours     unless hours

    if choice == :time
      return fail_at :time      unless hours[:time]
      return hours[:time]
    end
    if choice == :time_each
    return fail_at :time_each unless hours[:time_each] and hours[:time] == hours[:time_each]
      return hours[:time_each]
    end
    if choice == :salary
    return fail_at :salary    unless salary_total.class == Euro
      return hours[:salary]
    end
    if choice == :caterers
      return hours[:caterers]
    end
    if choice == :salary_total
      return salary_total
    end
    if choice == :hours
      return hours
    end
  end

end
