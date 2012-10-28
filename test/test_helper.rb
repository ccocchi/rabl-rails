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

require 'rabl-rails'
require 'plist'

RablRails.plist_engine = Plist::Emit

module ActiveSupport
  class TestCase
    RSpec::Mocks::setup(self)
    include RSpec::Mocks::ExampleMethods
  end
end

class Context
  attr_writer :virtual_path

  def initialize
    @_assigns = {}
    @virtual_path = nil
  end

  def assigns
    @_assigns
  end

  def params
    {}
  end
end

class User
  attr_accessor :id, :name, :sex
  def initialize(id=nil, name=nil, sex=nil)
    @id = id
    @name = name
    @sex = sex
  end
end