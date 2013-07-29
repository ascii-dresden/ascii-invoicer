require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

describe Invoicer do
  # it loads yml files
  # it matches addresses correctly
  # it sums up correctly
  # it detects duplicate entries

  before do
    @settings                         = {}
    @settings['templates']            = {}
    @settings['templates']['offer']   = "latex/ascii-angebot.tex"
    @settings['templates']['invoice'] = "latex/ascii-rechnung.tex"

    @test_project_path = File.join File.dirname(__FILE__), "test_projects"
    #@test_projects = (0..1).to_a.map{|n| File.join @test_project_path, n.to_s + '.yml'}
    @test_projects = {}
    Dir.glob(File.join @test_project_path, "*.yml" ).map{|name| @test_projects[File.basename(name, '.yml')] = name}

    @invoicer  = Invoicer.new @settings
    @invoicer2 = Invoicer.new @settings
    @invoicer3 = Invoicer.new @settings
    @invoicer4 = Invoicer.new @settings
    @invoicer5 = Invoicer.new @settings
  end

  describe "#initialize" do

    it "loads template files" do
      File.should exist @settings['templates']['offer']
      File.should exist @settings['templates']['invoice']
      @invoicer.load_templates().should be true
    end
  end

  describe "#load_project" do

    it "loads project file" do
      File.should exist @test_projects['alright']
      @invoicer.load_project @test_projects['alright']
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

    it "prints the data" do
      name = "alright"
      raw = @invoicer.load_project @test_projects[name]
      @invoicer.parse_project_date(raw).should be true
      @invoicer.validate()
      #@invoicer.print_data()
      puts @invoicer.tex_product_table()
    end

    it "validates alright" do
      File.should exist @test_projects['alright']
      @invoicer.load_project @test_projects['alright']
      @invoicer.validate().should be true
    end

    it "validates email addresses" do
      @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_email({'email' => "john.doe@com"}).should be_true
      @invoicer.parse_project_email({'email' => "john.doeexample.com"}).should be_false
      @invoicer.parse_project_email({'email' => "john.doe@@example.com"}).should be_false
      @invoicer.parse_project_email({'email' => ".@.com"}).should be_false

      @invoicer.parse_project_email({'email' => "john.doe@example.com"}).should be_true
    end

    it "validates the date" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_date(raw).should be true
      @invoicer.project_data['date'].should === Date.new(2013,7,20)

      File.should exist @test_projects['missing_date']
      raw = @invoicer2.load_project @test_projects['missing_date']
      @invoicer2.parse_project_date(raw).should be false
      @invoicer2.validate().should be false

      File.should exist @test_projects['broken_date']
      raw = @invoicer3.load_project @test_projects['broken_date']
      @invoicer3.parse_project_date(raw).should be false
    end

    it "validates date ranges" do
      File.should exist @test_projects['date_range']
      raw = @invoicer2.load_project @test_projects['date_range']
      @invoicer2.parse_project_date(raw).should be true
      @invoicer2.project_data['date'].should === Date.new(2013,7,20)
      @invoicer2.project_data['date_end'].should === Date.new(2013,7,26)
    end

    it "validates numbers" do
      File.should exist @test_projects['alright']
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.validate().should be true
      @invoicer.project_data['numbers']['offer'].should === Date.today.strftime("A%Y%m%d-1")
      @invoicer.project_data['numbers']['invoice_long'].should === "R2013-027"
      @invoicer.project_data['numbers']['invoice_short'].should === "R027"
    end

    it "validates client" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_client(raw).should be true
      @invoicer.project_data['client']['last_name'].should === 'Doe'
      @invoicer.project_data['client']['addressing'].should === 'Sehr geehrter Herr Doe'
    end

    it "validates missing client" do
      File.should exist @test_projects['missing_client']
      @invoicer.load_project @test_projects['missing_client']
      @invoicer.validate().should be false
    end

    it "validates long client" do
      name = 'client_long_title'
      name2 = 'client_long_title2'
      name3 = 'client_long_title3'
      name4 = 'client_female'
      File.should exist @test_projects[name]
      raw = @invoicer.load_project @test_projects[name]
      @invoicer.parse_project_client(raw).should be true
      @invoicer.project_data['client']['last_name'].should === 'Doe'
      @invoicer.project_data['client']['addressing'].should === 'Sehr geehrter Professor Dr. Dr. Doe'

      File.should exist @test_projects[name2]
      raw = @invoicer2.load_project @test_projects[name2]
      @invoicer2.parse_project_client(raw).should be true
      @invoicer2.project_data['client']['last_name'].should === 'Doe'
      @invoicer2.project_data['client']['addressing'].should === 'Sehr geehrte Frau Professor Dr. Dr. Doe'

      File.should exist @test_projects[name3]
      raw = @invoicer3.load_project @test_projects[name3]
      @invoicer3.parse_project_client(raw).should be true
      @invoicer3.project_data['client']['last_name'].should === 'Doe'
      @invoicer3.project_data['client']['addressing'].should === 'Sehr geehrter Herr Professor Dr. Dr. Doe'

      File.should exist @test_projects[name4]
      raw = @invoicer4.load_project @test_projects[name4]
      @invoicer4.parse_project_client(raw).should be true
      @invoicer4.project_data['client']['last_name'].should === 'Doe'
      @invoicer4.project_data['client']['addressing'].should === 'Sehr geehrte Frau Doe'
    end

    it "validates caterer" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_signature(raw).should be true
      @invoicer.project_data['caterer'].should === 'Yours Truely'

      raw = @invoicer2.load_project @test_projects['signature_long']
      @invoicer2.parse_project_signature(raw).should be true
      @invoicer2.project_data['caterer'].should === 'Hendrik Sollich'

      raw = @invoicer3.load_project @test_projects['old_signature']
      @invoicer3.parse_project_signature(raw).should be true
      pp @invoicer3.raw_project_data['signature']
      @invoicer3.project_data['caterer'].should === 'Yours Truely'
    end

    it "validates signature" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_signature(raw).should be true
      @invoicer.project_data['signature'].should === 'Yours Truely'

      raw = @invoicer2.load_project @test_projects['signature_long']
      @invoicer2.parse_project_signature(raw).should be true
      @invoicer2.project_data['signature'].should === "Yours Truely\nHendrik Sollich"
    end

    it "validates hours" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_hours(raw).should be true

      raw = @invoicer2.load_project @test_projects['hours_missmatching']
      @invoicer2.parse_project_hours(raw).should be false

      raw = @invoicer3.load_project @test_projects['hours_simple']
      @invoicer3.parse_project_hours(raw).should be true

      raw = @invoicer4.load_project @test_projects['hours_missing']
      @invoicer4.parse_project_hours(raw).should be false

      raw = @invoicer5.load_project @test_projects['hours_missing_salary']
      @invoicer5.parse_project_hours(raw).should be false

    end

    it "validates products" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_products(raw).should be true

      raw = @invoicer2.load_project @test_projects['products_missing']
      @invoicer2.parse_project_products(raw).should be false

      raw = @invoicer3.load_project @test_projects['products_empty']
      @invoicer3.parse_project_products(raw).should be false

      raw = @invoicer4.load_project @test_projects['products_soldandreturned']
      @invoicer4.parse_project_products(raw).should be false

      ## cant be tested because YAML::load already eliminates the duplicate
      #raw = @invoicer5.load_project @test_projects['products_name_twice']
      #@invoicer5.parse_project_products(raw).should be false
    end

    it "sums up products" do
      raw = @invoicer.load_project @test_projects['alright']
      @invoicer.parse_project_products(raw).should be true
      #pp @invoicer.project_data['products']
      @invoicer.project_data['products']['sums']['offered'].should       === 50.14
      @invoicer.project_data['products']['sums']['invoiced'].should     === 31.55
      @invoicer.project_data['products']['sums']['offered_tax'].should   === 59.67
      @invoicer.project_data['products']['sums']['invoiced_tax'].should === 37.54
    end

    #it "validates for invoices" do
    #  # Rechnungsnummer
    #end

    #it "validates for offers" do
    #end

  end

end
