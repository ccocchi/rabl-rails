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

  autoload :Responder, 'rabl-rails/responder'

  mattr_accessor :cache_templates
  @@cache_templates = true

  mattr_accessor :include_json_root
  @@include_json_root = true

  mattr_reader :json_engine
  @@json_engine = :yajl

  mattr_accessor :use_custom_responder
  @@use_custom_responder = false

  mattr_accessor :responder_default_template
  @@responder_default_template = 'show'

  def self.configure
    yield self

    ActionController::Base.responder = Responder if self.use_custom_responder
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
