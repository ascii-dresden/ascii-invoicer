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
      lambda{1 + @e}.should   raise_error(TypeError)
      lambda{1.0 + @e}.should raise_error(TypeError)

      a.should be_a Euro
      a.should === Euro.new(2)

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

      d = Euro.new(2.0) * Euro.new(2.0)
      d.should be_a Euro
      d.should === "4.00€"

    end

    it "compares" do
      Euro.new(1).should   === Euro.new(1)
      Euro.new(2.0).should === Euro.new(2)
      Euro.new(3).should   === Euro.new(3.0)
      (Euro.new(3)         ==  Euro.new(3.0)).should be true
    end

    it "converts from Rational" do
      a = '24/7'.to_r.to_euro
      a.should be_a Euro

      b = '17/5'.to_r.to_euro * '6/8'.to_r
      b.should be_a Euro

      c = '17/5'.to_r.to_euro * '6/8'.to_r
      c.should be_a Euro
    end

    it "converts from Euro" do
      Euro.new(2.0).to_euro.should be_a Euro
    end

    it "converts from Float" do
      a = 17.5.to_euro
      a.should be_a Euro

      b = 17.5.to_euro * 6.8
      b.should be_a Euro

      c = 17.5.to_euro * 6.8.to_euro
      c.should be_a Euro
    end

  end

end
