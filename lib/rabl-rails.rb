require 'active_support'

require 'rabl-rails/version'
require 'rabl-rails/helpers'
require 'rabl-rails/exceptions'
require 'rabl-rails/template'
require 'rabl-rails/nodes'
require 'rabl-rails/compiler'

require 'rabl-rails/visitors'
require 'rabl-rails/renderers/hash'
require 'rabl-rails/renderers/json'
require 'rabl-rails/renderers/xml'
require 'rabl-rails/renderers/plist'
require 'rabl-rails/library'

require 'rabl-rails/handler'

if defined?(Rails)
  require 'rails/railtie'
  require 'rabl-rails/railtie'
end

require 'rabl-rails/configuration'

begin
  require 'oj'
  Oj.default_options =  { mode: :compat, time_format: :ruby }
rescue LoadError
  require 'json'
end

module RablRails
  class << self
    def configure
      yield configuration
    end

    def configuration
      @_configuration ||= Configuration.new
    end

    def reset_configuration
      @_configuration = nil
    end
  end
end
