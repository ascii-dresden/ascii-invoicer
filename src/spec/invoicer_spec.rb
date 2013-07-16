require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

describe Invoicer do
  # it loads yml files
  # it matches addresses correctly
  # it sums up correctly
  # it detects duplicate entries

  before do
    @settings                          = OpenStruct.new
    @settings.path                     = './'
    @settings.template_files           = {}
    @settings.template_files[:offer]   = "latex/ascii-angebot.tex"
    @settings.template_files[:invoice] = "latex/ascii-rechnung.tex"
  end

  describe "#initialize" do

    it "loads all files" do
      File.should exist @settings.template_files[:offer]
      File.should exist @settings.template_files[:invoice]
    end

  end

end
