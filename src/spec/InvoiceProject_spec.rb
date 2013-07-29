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

    it "loads template files" do
      File.should exist @settings['templates']['offer']
      File.should exist @settings['templates']['invoice']
      @project.load_templates().should be true
    end
  end

  describe "#parse" do

    it "loads project file" do
      File.should exist @test_projects['alright']
      @project.parse @test_projects['alright']
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
      raw = @project.parse @test_projects[name]
      @project.parse_date(raw).should be true
      #@project.print_data()
      #puts @project.tex_product_table()
    end

    #it "validates alright invoice as alright" do
    #  File.should exist @test_projects['alright']
    #  @project.parse @test_projects['alright']
    #end

    it "validates email addresses" do
      @project.parse @test_projects['alright']
      @project.parse_email({'email' => "john.doe@com"}).should be_true
      @project.parse_email({'email' => "john.doeexample.com"}).should be_false
      @project.parse_email({'email' => "john.doe@@example.com"}).should be_false
      @project.parse_email({'email' => ".@.com"}).should be_false

      @project.parse_email({'email' => "john.doe@example.com"}).should be_true
    end

    it "validates the date" do
      raw = @project.parse @test_projects['alright']
      @project.parse_date(raw).should be true
      @project.read(:date).should === Date.new(2013,7,20)

      File.should exist @test_projects['missing_date']
      raw = @project2.parse @test_projects['missing_date']
      @project2.parse_date(raw).should be false

      File.should exist @test_projects['broken_date']
      raw = @project3.parse @test_projects['broken_date']
      @project3.parse_date(raw).should be false
    end

    it "validates date ranges" do
      File.should exist @test_projects['date_range']
      raw = @project2.parse @test_projects['date_range']
      @project2.parse_date(raw).should be true
      @project2.read(:date).should     === Date.new(2013,7,20)
      @project2.read(:date_end).should === Date.new(2013,7,26)
    end

    it "validates numbers" do
      File.should exist @test_projects['alright']
      raw = @project.parse @test_projects['alright']
      @project.parse_numbers raw
      @project.read(:numbers)[:offer].should === Date.today.strftime("A%Y%m%d-1")
      @project.read(:numbers)[:invoice_long].should === "R2013-027"
      @project.read(:numbers)[:invoice_short].should === "R027"
    end

    it "validates client" do
      raw = @project.parse @test_projects['alright']
      @project.parse_client(raw).should be true
      @project.read(:client)[:last_name].should === 'Doe'
      @project.read(:client)[:addressing].should === 'Sehr geehrter Herr Doe'
    end

    it "validates missing client" do
      File.should exist @test_projects['missing_client']
      @project.parse @test_projects['missing_client']
    end

    it "validates long client" do
      name = 'client_long_title'
      name2 = 'client_long_title2'
      name3 = 'client_long_title3'
      name4 = 'client_female'
      File.should exist @test_projects[name]
      raw = @project.parse @test_projects[name]
      @project.parse_client(raw).should be true
      @project.read(:client)[:last_name].should === 'Doe'
      @project.read(:client)[:addressing].should === 'Sehr geehrter Professor Dr. Dr. Doe'

      File.should exist @test_projects[name2]
      raw = @project2.parse @test_projects[name2]
      @project2.parse_client(raw).should be true
      @project2.read(:client)[:last_name].should === 'Doe'
      @project2.read(:client)[:addressing].should === 'Sehr geehrte Frau Professor Dr. Dr. Doe'

      File.should exist @test_projects[name3]
      raw = @project3.parse @test_projects[name3]
      @project3.parse_client(raw).should be true
      @project3.read(:client)[:last_name].should === 'Doe'
      @project3.read(:client)[:addressing].should === 'Sehr geehrter Herr Professor Dr. Dr. Doe'

      File.should exist @test_projects[name4]
      raw = @project4.parse @test_projects[name4]
      @project4.parse_client(raw).should be true
      @project4.read(:client)[:last_name].should === 'Doe'
      @project4.read(:client)[:addressing].should === 'Sehr geehrte Frau Doe'
    end

    it "validates caterer" do
      raw = @project.parse @test_projects['alright']
      @project.parse_signature(raw).should be true
      @project.read(:caterer).should === 'Yours Truely'

      raw = @project2.parse @test_projects['signature_long']
      @project2.parse_signature(raw).should be true
      @project2.read(:caterer).should === 'Hendrik Sollich'

      raw = @project3.parse @test_projects['old_signature']
      @project3.parse_signature(raw).should be true
      #pp @project3.raw_data['signature']
      @project3.read(:caterer).should === 'Yours Truely'
    end

    it "validates signature" do
      raw = @project.parse @test_projects['alright']
      @project.parse_signature(raw).should be true
      @project.read(:signature).should === 'Yours Truely'

      raw = @project2.parse @test_projects['signature_long']
      @project2.parse_signature(raw).should be true
      @project2.read(:signature).should === "Yours Truely\nHendrik Sollich"
    end

    it "validates hours" do
      raw = @project.parse @test_projects['alright']
      @project.parse_hours(raw).should be true

      raw = @project2.parse @test_projects['hours_missmatching']
      @project2.parse_hours(raw).should be false

      raw = @project3.parse @test_projects['hours_simple']
      @project3.parse_hours(raw).should be true

      raw = @project4.parse @test_projects['hours_missing']
      @project4.parse_hours(raw).should be false

      raw = @project5.parse @test_projects['hours_missing_salary']
      @project5.parse_hours(raw).should be false

    end

    it "validates products" do
      raw = @project.parse @test_projects['alright']
      @project.parse_products(raw).should be true

      raw = @project2.parse @test_projects['products_missing']
      @project2.parse_products(raw).should be false

      raw = @project3.parse @test_projects['products_empty']
      @project3.parse_products(raw).should be false

      raw = @project4.parse @test_projects['products_soldandreturned']
      @project4.parse_products(raw).should be false

      ## cant be tested because YAML::load already eliminates the duplicate
      #raw = @project5.parse @test_projects['products_name_twice']
      #@project5.parse_products(raw).should be false
    end

    it "sums up products" do
      raw = @project.parse @test_projects['alright']
      @project.parse_products(raw).should be true
      #pp @project.data['products']
      @project.get_cost(:offer).should      === 50.14
      @project.get_cost(:invoice).should     === 31.55
      @project.read(:products)['sums']['offered_tax'].should  === 59.67
      @project.read(:products)['sums']['invoiced_tax'].should === 37.54
    end

    #it "validates for invoices" do
    #  # Rechnungsnummer
    #end

    #it "validates for offers" do
    #end

  end

end
