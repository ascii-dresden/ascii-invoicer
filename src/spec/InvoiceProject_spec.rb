# encoding: utf-8
require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

$SETTINGS = YAML::load(File.open(File.join File.dirname(__FILE__), "/settings.yml"))

describe InvoiceProject do
  # it loads yml files
  # it matches addresses correctly
  # it sums up correctly
  # it detects duplicate entries

  before do
    @settings = $SETTINGS

    @test_project_path = File.join File.dirname(__FILE__), "test_projects"
    #@test_projects = (0..1).to_a.map{|n| File.join @test_project_path, n.to_s + '.yml'}
    @test_projects = {}
    Dir.glob(File.join @test_project_path, "*.yml" ).map{|name| @test_projects[File.basename(name, '.yml')] = name}

    @project  = InvoiceProject.new @settings
    @project2 = InvoiceProject.new @settings
    @project3 = InvoiceProject.new @settings
    @project4 = InvoiceProject.new @settings
    @project5 = InvoiceProject.new @settings
  end

  describe "#initialize" do
    #it "loads template files" do
    #  expect(File).to exist @settings['templates']['offer']
    #  expect(File).to exist @settings['templates']['invoice']
    #  expect(@project.load_templates()).to be true
    #end
  end

  describe "#open" do
    it "loads project file" do
      expect(File).to exist @test_projects['alright']
      @project.open @test_projects['alright']
    end

    it "refuses to load a second project file" do
      expect(File).to exist @test_projects['alright']
      @project.open @test_projects['alright']
      expect{@project.open(@test_projects['alright'])}.to raise_exception
    end
  end

  describe "#strpdates" do
    it "parses single dates" do
      dates = @project.strpdates("17.07.2013")
      expect(dates).to be_an_instance_of Array
      expect(dates[0]).to be_an_instance_of Date
      expect(dates[0]).to be == Date.new(2013,07,17)
    end

    it "parses pairs of dates" do
      dates = @project.strpdates("17-18.07.2013")
      expect(dates).to be_an_instance_of Array
      expect(dates[0]).to be_an_instance_of Date
      expect(dates[0]).to be == Date.new(2013,07,17)
      expect(dates[1]).to be_an_instance_of Date
      expect(dates[1]).to be == Date.new(2013,07,18)
    end
  end

  describe "#validate" do

    it "prints the data" do
      name = "alright"
      @project.open @test_projects[name]
      expect(@project.parse_date()).to be_truthy
      #@project.print_data()
      #puts @project.tex_product_table()
    end

    it "validates email addresses" do
      @project.open @test_projects['alright']
      @project.raw_data = {'email' => "john.doe@com"}
      expect(@project.parse_email()).to be_truthy
      @project.raw_data = {'email' => "john.doeexample.com"}
      expect(@project.parse_email()).to be_falsey
      @project.raw_data = {'email' => "john.doe@@example.com"}
      expect(@project.parse_email()).to be_falsey
      @project.raw_data = {'email' => ".@.com"}
      expect(@project.parse_email()).to be_falsey

      @project.raw_data =  {'email' => "john.doe@example.com"}
      expect(@project.parse_email()).to be_truthy
    end

    it "validates the date" do
      @project.open @test_projects['alright']
      expect(@project.parse_date()).to be_truthy
      @project.parse :date
      expect(@project.data[:date]).to eq Date.new(2013,7,20)

      expect(File).to exist @test_projects['missing_date']
      @project2.open @test_projects['missing_date']
      expect(@project2.parse_date()).to be false

      expect(File).to exist @test_projects['broken_date']
      @project3.open @test_projects['broken_date']
      expect(@project3.parse_date()).to be false
    end

    it "validates date ranges" do
      expect(File).to exist @test_projects['date_range']
      @project2.open @test_projects['date_range']
      expect(@project2.parse_date()).to be_truthy
      @project2.parse :date
      @project2.parse :date_end, :parse_date,:end
      expect(@project2.data[:date]).to     eq Date.new(2013,7,20)
      expect(@project2.data[:date_end]).to eq Date.new(2013,7,26)

      expect(File).to exist @test_projects['date_range2']
      @project3.open @test_projects['date_range2']
      expect(@project3.parse_date()).to be_truthy
      @project3.parse :date
      @project3.parse :date_end, :parse_date,:end
      expect(@project3.data[:date]).to     eq Date.new(2013,7,20)
      expect(@project3.data[:date_end]).to eq Date.new(2013,7,26)

      expect(File).to exist @test_projects['date_range3']
      @project4.open @test_projects['date_range3']
      expect(@project4.parse_date()).to be_truthy
      @project4.parse :date
      @project4.parse :date_end, :parse_date,:end
      expect(@project4.data[:date]).to     eq Date.new(2013,7,20)
      expect(@project4.data[:date_end]).to eq Date.new(2013,7,26)
    end

    it "validates numbers" do
      expect(File).to exist @test_projects['alright']
      @project.open @test_projects['alright']
      @project.parse :offer_number
      @project.parse :invoice_number
      @project.parse :invoice_number_long
      expect(@project.data[:offer_number]).to eq Date.today.strftime("A%Y%m%d-1")
      expect(@project.data[:invoice_number]).to eq "R027"
      expect(@project.data[:invoice_number_long]).to eq "R2013-027"
    end

    it "validates client" do
      @project.open @test_projects['alright']
      expect(@project.parse(:client)).to be_truthy
      expect(@project.data[:client][:last_name]).to  eq 'Doe'
      expect(@project.data[:client][:addressing]).to eq 'Sehr geehrter Herr Doe'
    end

    it "validates missing client" do
      expect(File).to exist @test_projects['missing_client']
      @project.open @test_projects['missing_client']
    end

    it "validates long client" do
      name = 'client_long_title'
      name2 = 'client_long_title2'
      name3 = 'client_long_title3'
      name4 = 'client_female'
      expect(File).to exist @test_projects[name]
      @project.open @test_projects[name]
      expect(@project.parse(:client)).to be_truthy
      @project.data[:client]
      expect(@project.data[:client][:last_name]).to eq 'Doe'
      expect(@project.data[:client][:addressing]).to eq 'Sehr geehrter Professor Dr. Dr. Doe'

      expect(File).to exist @test_projects[name2]
      @project2.open @test_projects[name2]
      expect(@project2.parse(:client)).to be_truthy
      expect(@project2.data[:client][:last_name]).to eq 'Doe'
      expect(@project2.data[:client][:addressing]).to eq 'Sehr geehrte Frau Professor Dr. Dr. Doe'

      expect(File).to exist @test_projects[name3]
      @project3.open @test_projects[name3]
      expect(@project3.parse(:client)).to be_truthy
      expect(@project3.data[:client][:last_name]).to eq 'Doe'
      expect(@project3.data[:client][:addressing]).to eq 'Sehr geehrter Herr Professor Dr. Dr. Doe'

      expect(File).to exist @test_projects[name4]
      @project4.open @test_projects[name4]
      expect(@project4.parse(:client)).to be_truthy
      expect(@project4.data[:client][:last_name]).to eq 'Doe'
      expect(@project4.data[:client][:addressing]).to eq 'Sehr geehrte Frau Doe'
    end

    it "validates manager" do
      expect(File).to exist @test_projects['alright']
      @project.open @test_projects['alright']
      expect(@project.parse(:manager)).to be_truthy
      expect(@project.data[:manager]).to eq 'Manager Bob'

      expect(File).to exist @test_projects['signature_long']
      @project2.open @test_projects['signature_long']
      expect(@project2.parse(:manager)).to be_truthy
      expect(@project2.data[:manager]).to eq 'Hendrik Sollich'

      #expect(File).to exist @test_projects['old_signature']
      #expect(@project3.open @test_projects['old_signature']
      #expect(@project3.parse(:manager)).to be_truthy
      #expect(@project3.data[:manager]).to eq 'Yours Truely'
    end

    it "validates signature" do
      @project.open @test_projects['alright']
      expect(@project.parse(:signature)).to be_truthy
      expect(@project.data[:signature]).to eq 'Mit freundlichen Grüßen'

      @project2.open @test_projects['signature_long']
      expect(@project2.parse(:signature)).to be_truthy
      expect(@project2.data[:signature]).to eq "Yours Truely\nHendrik Sollich"
    end

    it "validates hours" do
      @project.open @test_projects['alright']
      expect(@project.parse(:hours)).to be_truthy

      @project2.open @test_projects['hours_missmatching']
      expect(@project2.parse(:hours)).to be_truthy

      @project3.open @test_projects['hours_simple']
      expect(@project3.parse(:hours)).to be_truthy

      @project4.open @test_projects['hours_missing']
      expect(@project4.parse(:hours)).to be false

      @project5.open @test_projects['hours_missing_salary']
      expect(@project5.parse(:hours)).to be false
    end

    it "validates products" do
      @project.open @test_projects['alright']
      expect(@project.parse(:products)).to be_truthy

      @project2.open @test_projects['products_missing']
      expect(@project2.parse(:products)).to be false

      @project3.open @test_projects['products_empty']
      expect(@project3.parse(:products)).to be false

      @project4.open @test_projects['products_soldandreturned']
      expect(@project4.parse(:products)).to be false

      ## cant be tested because YAML::load already eliminates the duplicate
      #@project5.open @test_projects['products_name_twice']
      #@project5.parse(:products)).to be false
    end

    #it "sums up products" do
    #  @project.open @test_projects['alright']
    #  expect(@project.parse(:products)).to be_truthy
    #  @project.parse :products
    #  #pp @project.data['products']
    #  expect(@project.get_cost(:offer)).to    eq 50.14
    #  expect(@project.get_cost(:invoice)).to  eq 31.55
    #  expect(@project.data[:products]['sums']['offered_tax']).to  eq 59.67
    #  expect(@project.data[:products]['sums']['invoiced_tax']).to eq 37.54
    #end

    ##it "validates for invoices" do
    ##  # Rechnungsnummer
    ##end

    ##it "validates for offers" do
    ##end

  end

end
