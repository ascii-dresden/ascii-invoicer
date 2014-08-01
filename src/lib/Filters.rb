# encoding: utf-8
require 'date'

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

  def filter_manager string
    string
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


end
