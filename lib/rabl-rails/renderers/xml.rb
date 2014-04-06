require 'active_support/core_ext/hash/conversions'

module RablRails
  module Renderers
    module XML
      include Renderers::Hash
      extend self

      def format_output(hash, options = {})
      	xml_options = { root: options[:root_name] }.merge!(RablRails.configuration.xml_options)
				hash.to_xml(xml_options)
      end

      def resolve_cache_key(key, data)
        "#{super}.xml"
      end
    end
  end
end