require 'active_support/core_ext/hash/conversions'

module RablRails
  module Renderers
    class XML < Base
      DEFAULT_OPTIONS = { dasherize: true, skip_types: false }

      def format_output(hash)
      	xml_options = { root: _options[:root_name] }.merge!(DEFAULT_OPTIONS)
				hash.to_xml(xml_options)
      end
    end
  end
end