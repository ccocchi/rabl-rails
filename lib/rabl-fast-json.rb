require 'rails/railtie'

require 'active_support'
require 'active_support/json'
require 'active_support/core_ext/class/attribute_accessors'

require 'rabl-fast-json/version'
require 'rabl-fast-json/helpers'
require 'rabl-fast-json/template'
require 'rabl-fast-json/compiler'
require 'rabl-fast-json/library'
require 'rabl-fast-json/handler'
require 'rabl-fast-json/railtie'

module RablFastJson
  extend self
  
  mattr_accessor :cache_templates
  @@cache_templates = true

  def configure
    yield self
  end
  
  def cache_templates?
    ActionController::Base.perform_caching && @@cache_templates
  end
end
