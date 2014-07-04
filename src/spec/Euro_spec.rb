# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe Euro do

  before do
    @e = Euro.new 1
  end

  describe "#to_s" do
    it "creates string" do
      s = @e.to_s
      expect(s).to eq "1,00€"
      expect(s).to be_a String

      d = Euro.new 2.0
      t = d.to_s
      expect(t).to eq "2,00€"
      expect(t).to be_a String
      expect(d).to be_a Euro
    end
  end

  describe "calculation" do

    it "adds" do
      a = @e + 1
      expect{1 + @e}.to raise_error(TypeError)
      expect{1.0 + @e}.to raise_error(TypeError)

      expect(a).to be_a Euro
      expect(a).to eq Euro.new(2)

      d = Euro.new 2.0
      d += 1
      expect(d).to be_a Euro

      e = Euro.new 2.0
      e += 2.0
      expect(e).to be_a Euro

    end

    it "divides" do
      a = @e / 2
      expect(a).to be_a Euro
      expect(a).to eq Euro.new(0.5)
    end

    it "multiplies" do
      a = @e * 2
      expect(a).to be_a Euro
      expect(a).to eq Euro.new(2)

      b = @e * 2.0
      expect(b).to be_a Euro
      expect(b).to eq Euro.new(2)

      c = @e * -2.0
      expect(c).to be_a Euro
      expect(c).to eq Euro.new(-2)
      expect(c).to eq "-2.00€"

      d = Euro.new(2.0) * Euro.new(2.0)
      expect(d).to be_a Euro
      expect(d).to eq "4.00€"

    end

    it "compares" do
      expect(Euro.new(1)).to   eq Euro.new(1)
      expect(Euro.new(2.0)).to eq Euro.new(2)
      expect(Euro.new(3)).to   eq Euro.new(3.0)
      expect(Euro.new(3) ==  Euro.new(3.0)).to be true
    end

    it "converts from Rational" do
      a = '24/7'.to_r.to_euro
      expect(a).to be_a Euro

      b = '17/5'.to_r.to_euro * '6/8'.to_r
      expect(b).to be_a Euro

      c = '17/5'.to_r.to_euro * '6/8'.to_r
      expect(c).to be_a Euro
    end

    it "converts from Euro" do
      expect(Euro.new(2.0).to_euro).to be_a Euro
    end

    it "converts from Float" do
      a = 17.5.to_euro
      expect(a).to be_a Euro

      b = 17.5.to_euro * 6.8
      expect(b).to be_a Euro

      c = 17.5.to_euro * 6.8.to_euro
      expect(c).to be_a Euro
    end

  end

end
