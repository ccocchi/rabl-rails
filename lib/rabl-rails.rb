require 'rails/railtie'

require 'active_support'

require 'rabl-rails/version'
require 'rabl-rails/helpers'
require 'rabl-rails/template'
require 'rabl-rails/nodes'
require 'rabl-rails/compiler'

require 'rabl-rails/visitors'
require 'rabl-rails/renderer'
require 'rabl-rails/library'

require 'rabl-rails/handler'
require 'rabl-rails/railtie'

require 'rabl-rails/configuration'

begin
  require 'oj'
  Oj.default_options =  { mode: :compat, time_format: :ruby }
rescue LoadError
  require 'json'
end

module RablRails
  extend Renderer

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
