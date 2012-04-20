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



module RablRails
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
