# encoding: utf-8
class InvoiceProduct

  attr :name, :hash, :tax, :valid

  def initialize(name, hash, tax_value)
    @name = name
    @h = hash
    @tax_value = tax_value

    @valid = true
    validate()
  end

  def validate()
    @valid   = false if @h.nil?
    @valid   = false unless @h['sold'].nil? or @h['returned'].nil?
    @valid   = false unless @h['amount'] and @h['price']
    @sold    = @h['sold']
    @price   = @h['price']
    @amount  = @h['amount']
    @returnd = @h['returnd']

    if @sold
      @returned = @amount - @sold
    elsif @returned
      @sold = @amount - @returned
    else @sold = @amount
    end
  end

  def cost(type = :offer)
    return @cost_invoiced if type == :invoice
    return @cost_offered  if type == :offer
  end

  def tax(type = :offer)
    return @tax_invoiced if type == :invoice
    return @tax_offered  if type == :offer
  end

  def sum_up()
    @cost_invoiced = (@sold * @price).ceil_up()
    @cost_offered  = (@amount* @price).ceil_up()
    @tax_invoiced  = (@cost_invoiced * @tax_value).ceil_up()
    @tax_offerd    = (@cost_offered * @tax_value).ceil_up()
  end

end

