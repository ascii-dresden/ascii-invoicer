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

    @test_project_path = File.join File.dirname(__FILE__), "test_projects"
    @test_projects = (0..1).to_a.map{|n| File.join @test_project_path, n.to_s + '.yml'}

    @invoicer = Invoicer.new @settings
  end

  describe "#initialize" do

    it "loads template files" do
      File.should exist @settings.template_files[:offer]
      File.should exist @settings.template_files[:invoice]
      @invoicer.load_templates().should be true
    end
  end

  describe "#load_project" do

    it "loads project file" do
      File.should exist @test_projects[0]
      @invoicer.load_project @test_projects[0]
    end
  end

  describe "#strpdates" do
    it "parses single dates" do
      dates = @invoicer.strpdates("17.07.2013")
      dates.should be_an_instance_of Array
      dates[0].should be_an_instance_of Date
      dates[0].should be == Date.new(2013,07,17)
    end

    it "parses pairs of dates" do
      dates = @invoicer.strpdates("17-18.07.2013")
      dates.should be_an_instance_of Array
      dates[0].should be_an_instance_of Date
      dates[0].should be == Date.new(2013,07,17)
      dates[1].should be_an_instance_of Date
      dates[1].should be == Date.new(2013,07,18)
    end
  end

  describe "#validate" do

    it "validates the date" do
      @invoicer.load_project @test_projects[1]
      @invoicer.validate().should be true
      puts @invoicer.project_data
    end

    it "validates products" do
      @invoicer.load_project @test_projects[0]
      # each contains sold or returned or none not both
    end

  end

end
