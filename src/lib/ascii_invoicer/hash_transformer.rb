# encoding: utf-8
require 'hash-graft'

class HashTransformer
  attr_reader :original_hash, :new_hash
  attr_writer :rules

  def initialize(hash = {})
    @original_hash = hash[:original_hash]
    @original_hash ||= {}
    @new_hash = {}
    @rules = hash[:rules]
    @rules ||= []
  end

  def transform
    @new_hash = @original_hash
    @rules.each {|rule|
      @new_hash.set_path(rule[:new],  @original_hash.get_path(rule[:old]))
    }
    return @new_hash
  end

end
