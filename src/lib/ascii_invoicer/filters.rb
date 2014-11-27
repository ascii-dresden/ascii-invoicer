# encoding: utf-8
require 'date'
#require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'

module Filters


  def strpdates(string,pattern = nil)
    return [Date.today] unless string.class == String
    if pattern 
      return [Date.strptime(string, pattern).to_date]
    else
      p = string.split('.')
      p_range = p[0].split('-')

      if p_range.length == 1
        t = Date.new p[2].to_i, p[1].to_i, p[0].to_i
        return [t]

      elsif p_range.length == 2
        t1 = Date.new p[2].to_i, p[1].to_i, p_range[0].to_i
        t2 = Date.new p[2].to_i, p[1].to_i, p_range[1].to_i
        return [t1,t2]

      else
        fail
      end
    end
  end

  def check_email email
    email =~ $RFC5322
  end

  def filter_client_email email
    return fail_at :client_email unless check_email email
    email
  end

  def filter_canceled canceled
    @STATUS = :canceled if @STATUS != :unparsable and canceled
    canceled
  end

  def filter_event_dates dates
    dates.each {|d|
      unless d[:time].nil? or d[:end].nil? ## time and end is missleading
        @logger.warn "FILTER: #{name} missleading: time and end_date"
        return fail_at :event_dates
      end

      d[:begin] = Date.parse(d[:begin]) if d[:begin].class == String

      if not d[:time].nil?
        d[:time][:begin] = DateTime.strptime("#{d[:time][:begin]} #{d[:begin]}", "%H:%M %d.%m.%Y" ) if d[:time][:begin]
        d[:time][:end]   = DateTime.strptime("#{d[:time][:end]  } #{d[:begin]}", "%H:%M %d.%m.%Y" ) if d[:time][:end]
      end

      if d[:end].class == String
        d[:end] = Date.parse(d[:end])
      else
        d[:end] = d[:begin] 
      end
    }
    dates
  end

  def filter_event_description string
    return "" unless string
    string.strip
  end

  def filter_manager string
    string.strip
  end

  def filter_messages messages
    messages[ @data[:lang].to_sym ]
  end

  def filter_products products
    new_products = []
    products.each{|k,v|
      if [String, Symbol].include?  k.class 
        v[:name] = k
        new_products.push InvoiceProduct.new v , @settings
      elsif k.class == Hash
        new_products.push InvoiceProduct.new k.merge(v), @settings
        #new_products.push k.merge(v)
      else
        return k
        throw :filter_error
      end
    }

    return new_products
  end

  def filter_created date
    Date.parse date if date.class == String
  end

  def filter_offer_date date
    return Date.parse date if date.class == String
    return Date.today
  end

  def filter_invoice_number number
    return fail_at :invoice_number if number.nil?
    "R#{number.to_s.rjust(3, ?0)}"
  end

  def filter_invoice_date date
    return Date.parse date if date.class == String
    return Date.today
  end

  def filter_invoice_payed_date date
    return Date.parse date if date.class == String
    return fail_at :invoice_payed_date
  end

  def filter_hours_salary salary
    salary.to_euro
  end

end
