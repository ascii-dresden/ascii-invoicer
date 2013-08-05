# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe Euro do

  before do
    @e = Euro.new 1
  end

  describe "#to_s" do
    it "creates string" do
      s = @e.to_s
      s.should === "1,00€"
      s.should be_a String

      d = Euro.new 2.0
      t = d.to_s
      t.should === "2,00€"
      t.should be_a String
      d.should be_a Euro
    end
  end

  describe "calculation" do

    it "adds" do
      a = @e + 1
      b = 1 + @e
      c = 1.0 + @e

      a.should be_a Euro
      a.should === Euro.new(2)
      b.should be_a Float
      b.should === Euro.new(2)
      c.should be_a Float
      c.should === Euro.new(2)

      d = Euro.new 2.0
      d += 1
      d.should be_a Euro

      e = Euro.new 2.0
      e += 2.0
      e.should be_a Euro

    end

    it "divides" do
      a = @e / 2
      a.should be_a Euro
      a.should === Euro.new(0.5)
    end

    it "multiplies" do
      a = @e * 2
      a.should be_a Euro
      a.should === Euro.new(2)

      b = @e * 2.0
      b.should be_a Euro
      b.should === Euro.new(2)

      c = @e * -2.0
      c.should be_a Euro
      c.should === Euro.new(-2)
      c.should === "-2.00€"

    end

    it "compares" do
      Euro.new(1).should   === Euro.new(1)
      Euro.new(2.0).should === Euro.new(2)
      Euro.new(3).should   === Euro.new(3.0)
      (Euro.new(3)         ==  Euro.new(3.0)).should be true
    end

  end

end
