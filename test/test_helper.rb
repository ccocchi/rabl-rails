ENV["RAILS_ENV"] = "test"
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rspec/mocks'
require 'minitest/autorun'
require 'active_support/test_case'

require 'action_controller'

require 'singleton'
class <<Singleton
  def included_with_reset(klass)
    included_without_reset(klass)
    class <<klass
      def reset_instance
        Singleton.send :__init__, self
        self
      end
    end
  end
  alias_method_chain :included, :reset
end

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