require 'rails/railtie'

require 'active_support'
require 'active_support/core_ext/class/attribute_accessors'

require 'rabl-rails/version'
require 'rabl-rails/template'
require 'rabl-rails/nodes'
require 'rabl-rails/compiler'

require 'rabl-rails/visitors'
require 'rabl-rails/renderer'

require 'rabl-rails/library'
require 'rabl-rails/handler'
require 'rabl-rails/railtie'

begin
  require 'oj'
  Oj.default_options =  { mode: :compat, time_format: :ruby }
rescue LoadError
end

module RablRails
  extend Renderer

  autoload :Responder, 'rabl-rails/responder'

  mattr_accessor :cache_templates
  @@cache_templates = true

  mattr_accessor :include_json_root
  @@include_json_root = true

  mattr_accessor :use_custom_responder
  @@use_custom_responder = false

  mattr_accessor :responder_default_template
  @@responder_default_template = 'show'

  mattr_reader :plist_engine
  @@plist_engine = nil

  mattr_accessor :include_plist_root
  @@include_plist_root = false

  mattr_accessor :enable_jsonp_callbacks
  @@enable_jsonp_callbacks = false

  mattr_accessor :allow_empty_format_in_template
  @@allow_empty_format_in_template = false

  mattr_accessor :xml_options
  @@xml_options = { dasherize: true, skip_types: false }

  def self.configure
    yield self

    ActionController::Base.responder = Responder if self.use_custom_responder
  end

  def self.json_engine
    @json_engine ||= defined?(::Oj) ? ::Oj : ::JSON
  end

  def self.xml_engine=(name)
    ActiveSupport::XmlMini.backend = name
  rescue LoadError, NameError
    Rails.logger.warn %Q(WARNING: rabl-rails could not load "#{name}" as XML engine, fallback to default)
  end

  def self.xml_engine
    ActiveSupport::XmlMini.backend
  end

  def self.plist_engine=(name)
    raise "Your plist engine does not respond to #dump" unless name.respond_to?(:dump)
    @@plist_engine = name
  end

  def self.cache_templates?
    ActionController::Base.perform_caching && @@cache_templates
  end

  def self.load_default_engines!
    self.plist_engine = Plist::Emit if defined?(Plist)

    if defined?(LibXML)
      self.xml_engine = 'LibXML'
    elsif defined?(Nokogiri)
      self.xml_engine = 'Nokogiri'
    end
  end
end
