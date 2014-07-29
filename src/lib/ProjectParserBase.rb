# encoding: utf-8


class ProjectParserBase
  attr_reader :valid_for
  attr_writer :raw_data, :errors

  def initialize(settings = {},raw_data = {},parent = nil)
    @settings = settings
    @raw_data = raw_data
    @parent   = parent
    @valid_for = {}

    # TODO allow for alternative parser_matches
    @parser_matches = {
      #:key                => [parser,            parameters/key   ]
      :time_end            => [:parse_time,       :end             ] ,
      :date_end            => [:parse_date,       :end             ] ,
      :manager             => [:parse_signature,  :manager         ] ,
      :offer_number        => [:parse_numbers,    :offer           ] ,
      :invoice_number      => [:parse_numbers,    :invoice         ] ,
      :invoice_number_long => [:parse_numbers,    :invoice_long    ] ,
      :event               => [:parse_event,      :event           ] ,
      :address             => [:parse_simple,     :address         ] ,
      :tax                 => [:parse_simple,     :tax             ] ,
      :raw_date            => [:parse_simple,     :date            ] ,
      :description         => [:parse_simple,     :description     ] ,
      :request_message     => [:parse_simple,     :request_message ] ,
      :canceled            => [:parse_simple,     :canceled        ] ,

      :caterers            => [:parse_caterers,   :caterers        ] ,
      :costs_offer         => [:parse_costs,      :offer           ] ,
      :costs_invoice       => [:parse_costs,      :invoice         ] ,
      :taxes_offer         => [:parse_taxes,      :offer           ] ,
      :taxes_invoice       => [:parse_taxes,      :invoice         ] ,
      :total_offer         => [:parse_total,      :offer           ] ,
      :total_invoice       => [:parse_total,      :invoice         ] ,
      :final_offer         => [:parse_final,      :offer           ] ,
      :final_invoice       => [:parse_final,      :invoice         ] ,

      :tex_table_invoice   => [:parse_tex_table,  :invoice         ] ,
      :tex_table_offer     => [:parse_tex_table,  :offer           ] ,
      :hours               => [:parse_hours,      :time            ] ,
      :caterers            => [:parse_hours,      :caterers        ] ,
      :salary              => [:parse_hours,      :salary          ] ,
      :salary_total        => [:parse_hours,      :salary_total    ] ,
    }

    @parser_matches.each {|k,v| 
      begin 
        m = method v[0] 
      rescue
        puts "ERROR in parser_matches: #{v[0]} is no method"
        exit
      end
      }
  end

  def data
    @parent.data
  end

  ##
  # run validate() to initiate all parser functions.
  # If strikt = true the programm fails, otherise it returns false,
  def validate(type, print = false)
    return true  if data[:type] == type and data[:valid]
    return false if @STATUS == :unparsable
    data[:type] = type
    @valid_for = {}
    @settings['requirements'][type].each { |req| parse req }
    @settings['requirements'].each { |vtype, requirements|
      @valid_for[vtype] = true
      #puts vtype
      requirements.each { |req|
        puts "   " +
          "#{(!data[req].nil?).print} #{req.to_s.ljust(18)}" +
          "#{ data[req].to_s.each_line.first.to_s.each_line.first.strip }".ljust(18) +
          " (#{data[req].class})" if print and vtype == type
        if data[req].nil?
          @valid_for[vtype] = false
          #@errors.push req unless @errors.include? req
        end
      }
      puts if print and vtype == type
    }
    return true if data[:valid]
    false
  end

  ##
  # little parse function
  def parse(key, parser = "parse_#{key}", parameter = nil)
    return data[key] if data[key]
    warn "calling #{parser} eventhough this is unparsable" if @STATUS == :unparsable
    begin
      parser = method parser
    rescue NameError => error

      # look for mapping in @parser_matches
      if @parser_matches.keys.include? key
        pm = @parser_matches[key]
        return fail_at key unless pm[0] or pm[1]
        parse(key, pm[0], pm[1])
        return data[key]

      else
        data[key] = false
        return fail_at key

      end
    end

    unless parameter.nil?
      data[key] = parser.call(parameter)
    else
      data[key] = parser.call() 
    end
    return data[key]
  end

  def parse_simple key
    raw     = @raw_data[key.to_s]
    default = $SETTINGS["default_#{key.to_s}"]
    if raw
      return raw.strip if raw.class == String
      return raw
    end
    return default if default
    return fail_at key
  end

  def fail_at(*criteria)
    @parent.fail_at *criteria
  end
end

class NilClass
  def strip
    return ""
  end
end
