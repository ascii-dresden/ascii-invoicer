require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

$PATH = File.join ENV['HOME'] ,'Desktop','ram'
spec_path = File.join $PATH, 'spec_projects'

FileUtils.rm_rf spec_path if File.exists? spec_path

describe ProjectsPlumber do
  #this happens before every 'it'
  before do

    @settings               = OpenStruct.new
    @settings.path          = $PATH
    #@settings.path         = './'
    @settings.storage_dir   = "spec_projects/"
    @settings.working_dir   = "working/"
    @settings.archive_dir   = "archive/"
    @settings.template_file = "templates/vorlage.yml"
    @settings.silent        = true

    @plumber = described_class.new @settings
  end

  context "with no directories" do

    describe "#check_dir" do
      it "notices missing storage directory" do
        expect(@plumber.check_dir :storage).to be_false
      end

      it "notices missing working directory" do
        expect( @plumber.check_dir :working ).to be_false
      end

      it "notices missing archive directory" do
        expect( @plumber.check_dir :archive ).to be_false
      end

      it "finds its template file" do
        expect( @plumber.check_dir :template).to be_true
      end
    end

    describe "#create_dir" do
      it "refuses to create working directory without the storage directory" do
        expect(@plumber.create_dir :working).to be_false
      end

      it "refuses to create archive directory without the storage directory" do
        expect(@plumber.create_dir :archive).to be_false
      end
    end

    describe "#_new_project_folder" do
      it "refuses to create a new project_folder" do
        @plumber._new_project_folder("new_project_folder").should be_false
      end
    end

    describe "#create_dir" do
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

    #describe "#list_projects" do
    #  it "refuses to list projects if file does not exist" do
    #    @plumber.list_projects.should be_false
    #  end
    #end

  end


  context "with existing directories" do

    describe described_class, "#check_dir" do
      it "checks existing storage directory" do
        @plumber.check_dir (:storage ).should be_true
      end

      it "checks existing working directory" do
        expect( @plumber.check_dir :working ).to be_true
      end

      it "checks existing archive directory" do
        expect( @plumber.check_dir :archive ).to be_true
      end
    end

    describe described_class, "#_new_project_folder()" do
      it "creates a new project folder" do
        path = @plumber._new_project_folder "new_project0"
        expect(File).to exist path
      end
      it "refuses to create a project folder with existing name" do
        @plumber._new_project_folder("new_project0").should be_false
      end
    end

    describe described_class, "#new_project" do
      it "sanitizes names prior to creating new projects with forbidden characters" do
        subfolder     = @plumber.new_project("sub/folder")
        hiddenproject = @plumber.new_project(".hidden_project")
        subfolder.should be_true
        hiddenproject.should be_true
        @plumber.get_project_folder("sub_folder").should be_true
        @plumber.get_project_folder("hidden_project").should be_true
      end

      it "creates a new project" do
        @plumber.new_project("new_project1")
        @plumber.new_project("new_project2").should be_true
      end

      it "creates a new project with spaces in name" do
        name = "  fun project "
        @plumber.new_project(name)
        @plumber.get_project_file_path(name.strip).should be_true
        File.should exist @plumber.get_project_file_path(name.strip)
      end
    end

    describe described_class, "#get_project_folder" do
      #TODO test get_project_folder for :archive
      it "returns false for missing project folder" do
        @plumber.get_project_folder("nonexistent_project").should be_false
      end

      it "returns path to project folder" do
        File.should exist @plumber.get_project_folder("new_project1")
      end
    end

    describe described_class, "#get_project_file_path" do
      it "returns false for missing project" do
        @plumber.get_project_file_path("nonexistent_project").should be_false
      end

      it "returns path to project folder" do
        File.should exist @plumber.get_project_file_path("new_project1")
      end

    end

    describe "#list_projects" do
    #  it "lists projects" do
    #    @plumber.list_projects.should be_false
    #  end
    end

    describe "#archive_project" do

      it "moves project to archive" do
        name = "old_project"
        project = @plumber.new_project name
        @plumber.archive_project(name).should be_true
      end

      it "refuses to move non existent project to archive" do
        @plumber.archive_project("nonexistent_project").should be_false
      end

      it "moves project to archive, with special year" do
        name = "project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010).should be_true
      end

      it "moves project to archive, with special year and prefix" do
        name = "project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010, "R025_").should be_true
      end
    end

    describe "#unarchive_project" do


      it "moves project from archive to working_dir" do
        name = "reheated_project"
        project = @plumber.new_project name
        @plumber.archive_project(name).should be_true
      end

      it "refuses to move non existent project from archive to working_dir" do
        @plumber.archive_project("nonexistent_project").should be_false
      end

      it "moves project to archive, with special year" do
        name = "reheated_project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010).should be_true
        @plumber.unarchive_project(name, 2010).should be_true
      end

      it "moves project to archive, with special year and matching prefix" do
        name = "reheated_project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010, "R026_").should be_true
        @plumber.unarchive_project(name, 2010, "R026_").should be_true
      end

      it "moves project to archive, with special year and matching prefix" do
        name = "reheated_project_from_2011"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010, "R027_").should be_true
        @plumber.unarchive_project("R027_"+name, 2010, "R027_").should be_true
      end

      it "moves project to archive, with special year and not matching prefix" do
        name = "reheated_project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010, "R028_").should be_true
        @plumber.unarchive_project(name, 2010, "XXXX_").should be_false
      end

    end


  end
end
