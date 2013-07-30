#!/usr/bin/env ruby
# encoding: utf-8

require "./lib/InvoiceProject.rb"
require 'pp'

$SETTINGS = YAML::load(File.open("default-settings.yml"))

names =[
  #"date_range",
  "alright",
  "hours_missmatching",
  #"products_empty",
  #"products_missing",
  #"products_soldandreturned"
]

for name in names do
  project = InvoiceProject.new $SETTINGS, "./spec/test_projects/#{name}.yml"
  project.validate :display
  pp project.data
  #puts project.data.to_yaml
  puts; puts
end


#project.read(:products).each {|name, product| product.sum_up()}
#pp project.get_cost :offer
#pp project.get_cost :invoice


pp [:errors, project.errors] unless project.errors.length == 0
