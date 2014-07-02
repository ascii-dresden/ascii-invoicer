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
    #  File.should exist @settings['templates']['offer']
    #  File.should exist @settings['templates']['invoice']
    #  @project.load_templates().should be true
    #end
  end

  describe "#open" do
    it "loads project file" do
      File.should exist @test_projects['alright']
      @project.open @test_projects['alright']
    end
  end

  describe "#strpdates" do
    it "parses single dates" do
      dates = @project.strpdates("17.07.2013")
      dates.should be_an_instance_of Array
      dates[0].should be_an_instance_of Date
      dates[0].should be == Date.new(2013,07,17)
    end

    it "parses pairs of dates" do
      dates = @project.strpdates("17-18.07.2013")
      dates.should be_an_instance_of Array
      dates[0].should be_an_instance_of Date
      dates[0].should be == Date.new(2013,07,17)
      dates[1].should be_an_instance_of Date
      dates[1].should be == Date.new(2013,07,18)
    end
  end

  describe "#validate" do

    it "prints the data" do
      name = "alright"
      @project.open @test_projects[name]
      @project.parse_date().should be_truthy
      #@project.print_data()
      #puts @project.tex_product_table()
    end

    it "validates email addresses" do
      @project.open @test_projects['alright']
      @project.raw_data = {'email' => "john.doe@com"}
      @project.parse_email().should be_truthy
      @project.raw_data = {'email' => "john.doeexample.com"}
      @project.parse_email().should be_falsey
      @project.raw_data = {'email' => "john.doe@@example.com"}
      @project.parse_email().should be_falsey
      @project.raw_data = {'email' => ".@.com"}
      @project.parse_email().should be_falsey

      @project.raw_data =  {'email' => "john.doe@example.com"}
      @project.parse_email().should be_truthy
    end

    it "validates the date" do
      @project.open @test_projects['alright']
      @project.parse_date().should be_truthy
      @project.parse :date
      @project.data[:date].should === Date.new(2013,7,20)

      File.should exist @test_projects['missing_date']
      @project2.open @test_projects['missing_date']
      @project2.parse_date().should be false

      File.should exist @test_projects['broken_date']
      @project3.open @test_projects['broken_date']
      @project3.parse_date().should be false
    end

    it "validates date ranges" do
      File.should exist @test_projects['date_range']
      @project2.open @test_projects['date_range']
      @project2.parse_date().should be_truthy
      @project2.parse :date
      @project2.parse :date_end, :parse_date,:end
      @project2.data[:date].should     === Date.new(2013,7,20)
      @project2.data[:date_end].should === Date.new(2013,7,26)
    end

    it "validates numbers" do
      File.should exist @test_projects['alright']
      @project.open @test_projects['alright']
      @project.parse :offer_number
      @project.parse :invoice_number
      @project.parse :invoice_number_long
      @project.data[:offer_number].should === Date.today.strftime("A%Y%m%d-1")
      @project.data[:invoice_number].should === "R027"
      @project.data[:invoice_number_long].should === "R2013-027"
    end

    it "validates client" do
      @project.open @test_projects['alright']
      @project.parse(:client).should be_truthy
      @project.data[:client][:last_name].should  === 'Doe'
      @project.data[:client][:addressing].should === 'Sehr geehrter Herr Doe'
    end

    it "validates missing client" do
      File.should exist @test_projects['missing_client']
      @project.open @test_projects['missing_client']
    end

    it "validates long client" do
      name = 'client_long_title'
      name2 = 'client_long_title2'
      name3 = 'client_long_title3'
      name4 = 'client_female'
      File.should exist @test_projects[name]
      @project.open @test_projects[name]
      @project.parse(:client).should be_truthy
      @project.data[:client]
      @project.data[:client][:last_name].should === 'Doe'
      @project.data[:client][:addressing].should === 'Sehr geehrter Professor Dr. Dr. Doe'

      File.should exist @test_projects[name2]
      @project2.open @test_projects[name2]
      @project2.parse(:client).should be_truthy
      @project2.data[:client][:last_name].should === 'Doe'
      @project2.data[:client][:addressing].should === 'Sehr geehrte Frau Professor Dr. Dr. Doe'

      File.should exist @test_projects[name3]
      @project3.open @test_projects[name3]
      @project3.parse(:client).should be_truthy
      @project3.data[:client][:last_name].should === 'Doe'
      @project3.data[:client][:addressing].should === 'Sehr geehrter Herr Professor Dr. Dr. Doe'

      File.should exist @test_projects[name4]
      @project4.open @test_projects[name4]
      @project4.parse(:client).should be_truthy
      @project4.data[:client][:last_name].should === 'Doe'
      @project4.data[:client][:addressing].should === 'Sehr geehrte Frau Doe'
    end

    it "validates manager" do
      @project.open @test_projects['alright']
      @project.parse(:manager).should be_truthy
      @project.data[:manager].should === 'Manager Bob'

      @project2.open @test_projects['signature_long']
      @project2.parse(:manager).should be_truthy
      @project2.data[:manager].should === 'Hendrik Sollich'

      @project3.open @test_projects['old_signature']
      @project3.parse(:manager).should be_truthy
      @project3.data[:manager].should === 'Yours Truely'
    end

    it "validates signature" do
      @project.open @test_projects['alright']
      @project.parse(:signature).should be_truthy
      @project.data[:signature].should === 'Mit freundlichen Grüßen'

      @project2.open @test_projects['signature_long']
      @project2.parse(:signature).should be_truthy
      @project2.data[:signature].should === "Yours Truely\nHendrik Sollich"
    end

    it "validates hours" do
      @project.open @test_projects['alright']
      @project.parse(:hours).should be_truthy

      @project2.open @test_projects['hours_missmatching']
      @project2.parse(:hours).should be_truthy

      @project3.open @test_projects['hours_simple']
      @project3.parse(:hours).should be_truthy

      @project4.open @test_projects['hours_missing']
      @project4.parse(:hours).should be false

      @project5.open @test_projects['hours_missing_salary']
      @project5.parse(:hours).should be false
    end

    it "validates products" do
      @project.open @test_projects['alright']
      @project.parse(:products).should be_truthy

      @project2.open @test_projects['products_missing']
      @project2.parse(:products).should be false

      @project3.open @test_projects['products_empty']
      @project3.parse(:products).should be false

      @project4.open @test_projects['products_soldandreturned']
      @project4.parse(:products).should be false

      ## cant be tested because YAML::load already eliminates the duplicate
      #@project5.open @test_projects['products_name_twice']
      #@project5.parse(:products).should be false
    end

    #it "sums up products" do
    #  @project.open @test_projects['alright']
    #  @project.parse(:products).should be_truthy
    #  @project.parse :products
    #  #pp @project.data['products']
    #  @project.get_cost(:offer).should    === 50.14
    #  @project.get_cost(:invoice).should  === 31.55
    #  @project.data[:products]['sums']['offered_tax'].should  === 59.67
    #  @project.data[:products]['sums']['invoiced_tax'].should === 37.54
    #end

    ##it "validates for invoices" do
    ##  # Rechnungsnummer
    ##end

    ##it "validates for offers" do
    ##end

  end

end
