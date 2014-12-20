# encoding: utf-8

module Generators
  def generate_hours_total full_data
    hours = full_data[:hours]
    hours[:salary] * hours[:time]
  end

  def generate_hours_time full_data
    hours = full_data[:hours]
    sum = 0
    if hours[:caterers]
      hours[:caterers].values.each{|v| sum += v.rationalize}
      return sum.to_f
    elsif hours[:time]
      fail_at :caterers
      return hours[:time]
    end
    sum
  end

  def generate_client_fullname full_data
    client = full_data[:client]
    fail_at :client_first_name unless client[:first_name] 
    fail_at :client_last_name unless client[:last_name]
    return fail_at :client_fullname unless client[:first_name] and client[:last_name]
    return [client[:first_name], client[:last_name]].join ' '
  end

  def generate_client_addressing full_data
    return fail_at(:client_addressing) unless full_data[:client]
    return fail_at(:client_title) unless full_data[:client][:title]
    lang       = full_data[:lang]
    client     = full_data[:client]
    title      = client[:title].words.first.downcase
    gender     = @settings['gender_matches'][title]
    addressing = @settings['lang_addressing'][lang][gender]
    return "#{addressing} #{client[:title]} #{client[:last_name]}"
  end

  def generate_caterers full_data
    caterers = []
    full_data[:hours][:caterers].each{|name, time| caterers.push name} if full_data[:hours][:caterers]
    return caterers
  end

  def generate_event_date full_data
    Date.parse full_data[:event][:dates][0][:begin]  unless full_data[:event][:dates].nil?
  end

  def generate_event_calendaritems full_data
    begin
      events = []
      full_data[:event][:dates].each { |date|
        # TODO event times is not implemented right
        unless date[:times].nil?

          ## set specific times
          date[:times].each { |time|
            if time[:end]
              dtstart = DateTime.parse( date[:begin].strftime("%d.%m.%Y ") + time[:begin] )
              dtend   = DateTime.parse( date[:begin].strftime("%d.%m.%Y ") + time[:end] )
            else
              dtstart = Icalendar::Values::Date.new( date[:begin].strftime  "%Y%m%d")
              dtend   = Icalendar::Values::Date.new((date[:end]+1).strftime "%Y%m%d")
            end
            event = Icalendar::Event.new
            event.dtstart = dtstart
            event.dtend   = dtend
            events.push  event unless event.dtstart.nil?

          }

        else
          ## set full day event
          event = Icalendar::Event.new
          event.dtstart = Icalendar::Values::Date.new( date[:begin].strftime  "%Y%m%d")
          event.dtend   = Icalendar::Values::Date.new((date[:end]+1).strftime "%Y%m%d")
          events.push  event unless event.dtstart.nil?

        end

        events.each{ | event|

          event.description = ""
          event.summary     = full_data[:event][:name]
          event.summary  = "CANCELED: #{ event.summary }" if full_data[:canceled]

          event.description += "Verantwortung: " + full_data[:manager]      + "\n" if full_data[:manager]
          if full_data[:hours][:caterers]
            event.description +=  "Caterer:\n"
            full_data[:caterers].each {|caterer,time| event.description +=  " - #{ caterer}\n" }
          end

          event.description += full_data[:description]  + "\n" if full_data[:description]
        }
      }
      return events
    rescue
      @errors << :event_dates
      return false
    end
  end

  def generate_productsbytax full_data
    list = {}
    taxlist = {}
    full_data[:products].each {|product|
      list[product.tax_value] = [] unless list[product.tax_value]
      list[product.tax_value] << product
    }
    list.keys.sort.each{|key| taxlist[key] = list[key] } # sorting a hash by keys
    return taxlist
  end


  def sum_money key
    sum = 0.to_euro
    @data[:products].each{|p| sum += p.hash[key]} if @data[:products].class == Array
    sum.to_euro
  end

  def generate_event_date full_data
    full_data[:event][:dates][0][:begin] unless full_data[:event][:dates].nil?
  end

  def generate_event_prettydate full_data
    return fail_at :event_prettydate if full_data[:event][:dates].nil?
    date = full_data[:event][:dates][0]
    first = date[:begin]
    last = full_data[:event][:dates].last[:end]
    last = full_data[:event][:dates].last[:begin] if last.nil?

    return "#{first.strftime "%d"}-#{last.strftime "%d.%m.%Y"}" if first != last
    return first.strftime "%d.%m.%Y" if first.class == Date
    return first
  end

  def generate_offer_number full_data
    appendix  = full_data[:offer][:appendix]
    full_data[:offer][:date].strftime "A%Y%m%d-#{appendix}"
  end


  # costs: price of all products summed up
  # taxes: price of all products taxes summed up ( e.g. price*0.19 )
  # total: costs + taxes
  # final: total + salary * hours


  def generate_offer_costs full_data
    sum_money :cost_offer
  end

  def generate_offer_taxes full_data
    sum_money :tax_offer
  end

  def generate_offer_total full_data
    sum_money :total_offer
  end

  def generate_offer_final full_data
    full_data[:offer][:total] + full_data[:hours][:total]
  end




  def generate_invoice_costs full_data
    sum_money :cost_invoice
  end

  def generate_invoice_taxes full_data
    sum_money :tax_invoice
  end

  def generate_invoice_total full_data
    sum_money :total_invoice
  end

  def generate_invoice_final full_data
    full_data[:invoice][:total] + full_data[:hours][:total]
  end

  def generate_invoice_delay full_data
    return 0 if full_data[:canceled]
    return -(full_data[:event][:date] - full_data[:invoice][:date] if full_data[:invoice][:date]).to_i
    return -(full_data[:event][:date] - Date.today).to_i
  end

  def generate_invoice_paydelay full_data
    if full_data[:invoice][:payed_date] and full_data[:invoice][:date]
      delay = full_data[:invoice][:payed_date] - full_data[:invoice][:date]
      fail_at :invoice_payed if delay < 0
      return delay.to_i
    end
    return nil
  end

  def generate_invoice_longnumber full_data
    if full_data[:invoice][:date]
      year = full_data[:invoice][:date].year
      full_data[:invoice][:number].gsub /^R/, "R#{year}-" if full_data[:invoice][:number]
    end
  end

end
