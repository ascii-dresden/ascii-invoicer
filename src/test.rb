#!/usr/bin/env ruby
# encoding: utf-8

require "./lib/InvoiceProject.rb"
require 'pp'

$SETTINGS = YAML::load(File.open("default-settings.yml"))

project = InvoiceProject.new $SETTINGS
name = "alright"
#name = "products_empty"
#name = "products_missing`"
#name = "products_soldandreturned"
project.parse_project "./spec/test_projects/#{name}.yml"
project.read(:products).each {|name, product| product.sum_up()}
pp project.get_cost :offer
pp project.get_cost :invoice




puts
pp [:errors, project.errors]
