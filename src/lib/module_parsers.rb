# encoding: utf-8
module InvoiceParsers

  ##
  def parse_costs
    return fail_at :costs unless parse :tax
    return fail_at :costs unless parse :products
    return fail_at :costs unless parse :salary_total
    costs = {}
    costs[:cost_invoice] = 0.0
    costs[:cost_offer]   = 0.0
    costs[:tax_invoice]  = 0.0
    costs[:tax_offer]    = 0.0

    @data[:products].each { |name,product|
      costs[:cost_invoice] += product.cost_invoice
      costs[:cost_offer]   += product.cost_offer
      costs[:tax_invoice]  += product.tax_invoice  
      costs[:tax_offer]    += product.tax_offer    
    }
    costs[:total_invoice] = (costs[:cost_invoice] + costs[:tax_invoice]).ceil_up()
    costs[:total_offer]   = (costs[:cost_offer]   + costs[:tax_offer]).ceil_up()

    return costs

    false
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
      elsif @raw_data['anumber'].nil?
        numbers[:offer] = @raw_data['manumber']
      else
        numbers[:offer] = Date.today.strftime "A%Y%m%d-" + @raw_data['anumber'].to_s
      end
      return numbers[:offer]         if choice == :offer
    end
    return numbers
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
      return @raw_data["signature"] if choice == :signature
    end
    return fail_at :signature,:manager
  end


  ##
  def parse_hours(choice = :hours)
    hours            = {}
    hours[:time]     = @raw_data['hours']['time'].to_f
    hours[:salary]   = @raw_data['hours']['salary']
    hours[:caterers] = @raw_data['hours']['caterers']
    hours[:time_each] = 0.0

    hours[:caterers].each { |name,time|
      hours[:time_each] += time

    }

    salary = @raw_data['hours']['salary']
    salary_total   = salary * hours[:time]

    return fail_at :hours     unless hours
    return fail_at :time      unless hours[:time]
    return fail_at :time_each unless hours[:time] == hours[:time_each]
    return fail_at :salary    unless salary_total.class == Float

    return hours[:time]     if choice == :time
    return hours[:salary]   if choice == :salary
    return salary_total     if choice == :salary_total
    return hours[:caterers] if choice == :caterers
    return hours            if choice == :hours
  end

end
