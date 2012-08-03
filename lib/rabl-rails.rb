require 'rails/railtie'

require 'active_support'
require 'active_support/core_ext/class/attribute_accessors'

require 'rabl-rails/version'
require 'rabl-rails/template'
require 'rabl-rails/compiler'

require 'rabl-rails/renderer'

require 'rabl-rails/library'
require 'rabl-rails/handler'
require 'rabl-rails/railtie'

require 'multi_json'

module RablRails
  extend Renderer
  
  mattr_accessor :cache_templates
  @@cache_templates = true
  
  mattr_accessor :include_json_root
  @@include_json_root = true

  mattr_reader :json_engine
  @@json_engine = :yajl

  def self.configure
    yield self
  end
  
  def self.json_engine=(name)
    MultiJson.engine = name
    @@json_engine = name
  rescue LoadError
    Rails.logger.warn %Q(WARNING: rabl-rails could not load "#{self.json_engine}" as JSON engine, fallback to default)
  end
  
  def self.cache_templates?
    ActionController::Base.perform_caching && @@cache_templates
  end
  
  def self.load_default_engines!
    self.json_engine = :yajl
  end
end
