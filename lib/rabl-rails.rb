require 'rails/railtie'

require 'active_support'
require 'active_support/json'
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
  mattr_accessor :cache_templates
  @@cache_templates = true
  
  mattr_accessor :include_json_root
  @@include_json_root = true

  mattr_accessor :json_engine
  @@json_engine = :yajl

  def self.configure
    yield self
    post_configure
  end

  def self.cache_templates?
    ActionController::Base.perform_caching && @@cache_templates
  end

  private
  def self.post_configure
    MultiJson.engine = self.json_engine 
  end
end
