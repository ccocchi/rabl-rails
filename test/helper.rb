ENV['RAILS_ENV'] = 'test'
$:.unshift File.expand_path('../../lib', __FILE__)

# require 'rspec/mocks'
require 'minitest/mock'
require 'minitest/autorun'

require 'rabl-rails'
require 'plist'

if RUBY_ENGINE == 'jruby'
  require 'nokogiri'
elsif RUBY_ENGINE == 'ruby'
  require 'libxml'
end

RablRails.load_default_engines!

module Rails
  def self.cache; end
end

module ActionController
  module Base
    def self.perform_caching
      false
    end
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

  def context_method
  end
end

class User
  attr_accessor :id, :name

  def initialize(id = nil, name = nil)
    @id = id
    @name = name
  end
end