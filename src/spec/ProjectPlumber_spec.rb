require 'pp'
require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

$SETTINGS = YAML::load(File.open(File.join File.dirname(__FILE__), "/settings.yml"))
reset_path = File.join $SETTINGS['path'], $SETTINGS['dirs']['storage']
FileUtils.rm_rf reset_path if File.exists? reset_path

describe ProjectsPlumber do
  #this happens before every 'it'
  before do
    @plumber = described_class.new $SETTINGS
  end

  context "with no directories" do

    describe "#check_dir" do

      it "notices missing storage directory" do
        expect(@plumber.check_dir :storage).to be_falsey
      end

      it "notices missing working directory" do
        expect( @plumber.check_dir :working ).to be_falsey
      end

      it "notices missing archive directory" do
        expect( @plumber.check_dir :archive ).to be_falsey
      end

      it "finds its template file" do
        expect( @plumber.check_dir :template).to be_truthy
      end
    end

    describe "#create_dir" do
      it "refuses to create working directory without the storage directory" do
        expect(@plumber.create_dir :working).to be_falsey
      end

      it "refuses to create archive directory without the storage directory" do
        expect(@plumber.create_dir :archive).to be_falsey
      end
    end

    describe "#_new_project_folder" do
      it "refuses to create a new project_folder" do
        @plumber._new_project_folder("new_project_folder").should be_falsey
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
    #    @plumber.list_projects.should be_falsey
    #  end
    #end

  end


  context "with existing directories" do

    describe described_class, "#check_dir" do
      it "checks existing storage directory" do
        @plumber.check_dir (:storage ).should be_truthy
      end

      it "checks existing working directory" do
        expect( @plumber.check_dir :working ).to be_truthy
      end

      it "checks existing archive directory" do
        expect( @plumber.check_dir :archive ).to be_truthy
      end
    end

    describe described_class, "#_new_project_folder()" do
      it "creates a new project folder" do
        path = @plumber._new_project_folder "new_project0"
        expect(File).to exist path
      end
      it "refuses to create a project folder with existing name" do
        @plumber._new_project_folder("new_project0").should be_falsey
      end
    end

    describe described_class, "#new_project" do
      it "sanitizes names prior to creating new projects with forbidden characters" do
        subfolder     = @plumber.new_project("sub/folder")
        hiddenproject = @plumber.new_project(".hidden_project")
        subfolder.should be_truthy
        hiddenproject.should be_truthy
        @plumber.get_project_folder("sub_folder").should be_truthy
        @plumber.get_project_folder("hidden_project").should be_truthy
      end

      it "creates a new project" do
        @plumber.new_project("new_project1").should be_truthy
        @plumber.new_project("new_project2").should be_truthy
      end

      it "creates a new project with spaces in name" do
        name = "  fun project "
        @plumber.new_project(name)
        @plumber.get_project_file_path(name.strip).should be_truthy
        File.should exist @plumber.get_project_file_path(name.strip)
      end
    end

    describe described_class, "#get_project_folder" do
      #TODO test get_project_folder for :archive
      it "returns false for missing project folder" do
        @plumber.get_project_folder("nonexistent_project").should be_falsey
      end

      it "returns path to project folder" do
        File.should exist @plumber.get_project_folder("new_project1")
      end

      it "returns path to archived project folder" do
        name = "archived project for get_project_folder"
        @plumber.new_project name
        @plumber.archive_project name
        File.should exist @plumber.get_project_folder(name,:archive)
      end
    end

    describe described_class, "#get_project_file_path" do

      it "returns false for missing project" do
        @plumber.get_project_file_path("nonexistent_project").should be_falsey
      end

      it "returns path to project folder" do
        File.should exist @plumber.get_project_file_path("new_project1")
      end

      it "finds files in the archive" do
        name = "archived project"
        @plumber.new_project name
        @plumber.archive_project name
        @plumber.get_project_file_path(name, :archive).should be_truthy
        File.should exist @plumber.get_project_file_path(name, :archive)
      end

    end

    describe described_class, "#list_projects" do
    #  it "lists projects" do
    #    @plumber.list_projects.should be_falsey
    #  end
    end

    describe described_class, "#archive_project" do

      it "moves project to archive" do
        name = "old_project"
        project = @plumber.new_project name
        @plumber.archive_project(name).should be_truthy
      end

      it "refuses to move non existent project to archive" do
        @plumber.archive_project("nonexistent_project").should be_falsey
      end

      it "moves project to archive, with special year" do
        name = "project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010).should be_truthy
      end

      it "moves project to archive, with special year and prefix" do
        name = "project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name, 2010, "R025").should be_truthy
      end
    end

    describe described_class, "#unarchive_project" do

      it "moves project from archive to working_dir" do
        name = "reheated_project"
        project = @plumber.new_project name
        File.should exist project
        @plumber.archive_project(name).should be_truthy
        @plumber.unarchive_project(name).should be_truthy
      end

      it "moves project from archive to working_dir" do
        name = "old_project_from_2010"
        project = @plumber.new_project name
        @plumber.archive_project(name,2010).should be_truthy
        @plumber.unarchive_project(name,2010).should be_truthy
      end

      it "refuses to move non existent project from archive to working_dir" do
        @plumber.archive_project("nonexistent_project").should be_falsey
      end

      it "refuses to overwrite project already in archive" do
        name = "previously archived"
        project = @plumber.new_project name
        @plumber.archive_project(name).should be_truthy
        project = @plumber.new_project name
        @plumber.archive_project(name).should be_falsey
      end

      it "refuses to overwrite project in working from archive" do
        name = "dont_overwrite me"
        project = @plumber.new_project name
        @plumber.archive_project(name).should be_truthy
        project = @plumber.new_project name
        @plumber.unarchive_project(name).should be_falsey
      end

    end

  end

  context "generally" do

    it "handles space separated filenames" do
      name = "   space separated filename   "
      project = @plumber.new_project name
      File.should exist project
      @plumber.archive_project(name).should be_truthy
      @plumber.unarchive_project(name).should be_truthy
      @plumber.get_project_folder(name).should be_truthy
      @plumber.get_project_folder(name.strip).should be_truthy
    end

    it "handles dash separated filenames" do
      name = "dash/separated/filename"
      project = @plumber.new_project name
      File.should exist project
      @plumber.archive_project(name).should be_truthy
      @plumber.unarchive_project(name).should be_truthy
      @plumber.get_project_folder(name).should be_truthy
    end

    it "handles dot separated filenames" do
      name = "dot.separated.filename"
      project = @plumber.new_project name
      File.should exist project
      @plumber.archive_project(name).should be_truthy
      @plumber.unarchive_project(name).should be_truthy
      @plumber.get_project_folder(name).should be_truthy
    end

  end

end
