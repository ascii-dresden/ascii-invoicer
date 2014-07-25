# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe AsciiSanitizer do

  it "replaces umlaute equivalently" do
    expect(AsciiSanitizer.process("äëïöüß")).to eq "aeeioeuess"
  end

  it "replaces TM equivalently" do
    expect(AsciiSanitizer.process("™")).to eq "(TM)"
  end

  it "replaces symbols equivalently" do
    expect(AsciiSanitizer.process("♥")).to eq "<3"
  end

  it "replaces symbols equivalently" do
    expect(AsciiSanitizer.process("☺")).to eq ":)"
  end

  it "replaces spaces equivalently" do
    expect(AsciiSanitizer.process(" ")).to eq " "
  end

  it "handles german sentences " do
    expect(AsciiSanitizer.process("Schöne Grüße aus Dänemark!")).to eq "Schoene Gruesse aus Daenemark!"
  end

  it "corrects path names" do
    expect(AsciiSanitizer.clean_path "this is a path").to eq  "this is a path"
    expect(AsciiSanitizer.clean_path "this/is/a/path").to eq  "this_is_a_path"
    expect(AsciiSanitizer.clean_path ".this/is/a/path").to eq "this_is_a_path"
  end


end
