# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rspec/mocks'
require 'minitest/autorun'
require 'active_support/test_case'
require 'rabl-fast-json'

module ActiveSupport
  class TestCase
    RSpec::Mocks::setup(self)
    include RSpec::Mocks::ExampleMethods
  end
end

class Context
  attr_accessor :virtual_path

  def initialize
    @_assigns = {}
    @virtual_path = '/users'
  end

  def set_assign(key, value)
    @_assigns[key] = value
  end

  def get_assign(key)
    @_assigns[key]
  end
end

User = Struct.new(:id, :name, :sex)