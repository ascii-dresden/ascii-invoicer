require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

# hard coded name so you don't accidentally delete actual storage_dir
FileUtils.rm_rf "./spec_projects" if File.exists? "./spec_projects"

describe ProjectsPlumber do
  #this happens before every 'it'
  before do

    @settings             = OpenStruct.new
    @settings.path        = './'
    @settings.storage_dir = "#{@settings.path}spec_projects/"
    @settings.working_dir = "working/"
    @settings.archive_dir = "archive/"

    @plumber = described_class.new @settings
  end

  context "with no directories" do

    it "notices missing storage directory" do
      expect(@plumber.check_dir :storage).to be_false
    end

    it "notices missing working directory" do
      expect( @plumber.check_dir :working ).to be_false
    end

    it "notices missing archive directory" do
      expect( @plumber.check_dir :archive ).to be_false
    end

    it "refuses to create working directory without the storage directory" do
      expect(@plumber.create_dir :working).to be_false
    end

    it "refuses to create archive directory without the storage directory" do
      expect(@plumber.create_dir :archive).to be_false
    end

    it "creates the storage directory" do
      @plumber.create_dir :storage
      expect(File).to exist @plumber.dirs[:storage]
    end

    it "creates the working directory" do
      @plumber.create_dir :working
      expect(File).to exist @plumber.dirs[:working]
    end

    it "creates the archive directory" do
      @plumber.create_dir :archive
      expect(File).to exist @plumber.dirs[:archive]
    end
    
  end

  context "with existing directories" do

    it "checks existing storage directory" do
       @plumber.check_dir (:storage ).should be_true
    end

    it "checks existing working directory" do
      expect( @plumber.check_dir :working ).to be_true
    end

    it "checks existing archive directory" do
      expect( @plumber.check_dir :archive ).to be_true
    end

    #describe described_class, "#check_and_create" do
    #  it "returns true" do
    #    @plumber.check_and_create.should be_true
    #  end
    #end

  end

end
