# encoding: utf-8
require 'date'
#require File.join File.dirname(__FILE__) + '/rfc5322_regex.rb'

module Filters

  def strpdates(string,pattern = nil)
    return Date.today unless string
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
    fail_at :client_email unless check_email email
    email
  end

  def filter_event_description string
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
        new_products.push InvoiceProduct.new v
      elsif k.class == Hash
        new_products.push InvoiceProduct.new k.merge(v)
        #new_products.push k.merge(v)
      else
        return k
        throw :filter_error
      end
    }

    return new_products
    {}
  end

  def filter_created date
    strpdates date
  end

  def filter_offer_date date
    strpdates date
  end

  def filter_invoice_number number
    "R#{number}" unless number.nil? or number[0] == ?R
    @data[:invoice]
  end

  def filter_invoice_date date
    strpdates date
  end

  def filter_invoice_payed_date date
    strpdates date
  end

  def generate_hours_total full_data
    hours = full_data[:hours]
    sum = 0
    hours[:caterers].values.each{|v| sum += v}
    hours[:total]
    sum
  end

  def generate_client_addressing full_data
    #pp data[:client]
    lang       = full_data[:lang]
    client     = full_data[:client]
    title      = client[:title].downcase
    gender     = $SETTINGS['gender_matches'][title]
    addressing = $SETTINGS['lang_addressing'][lang][gender]
    "#{addressing} #{client[:title]} #{client[:last_name]}"
  end

  def generate_event_date  full_data
    Date.parse full_data[:event][:dates][0][:begin]
  end

end
