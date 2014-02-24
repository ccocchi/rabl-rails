require 'active_support/core_ext/hash/conversions'

module RablRails
  module Renderers
    class XML < Base
      def format_output(hash)
      	xml_options = { root: _options[:root_name] }.merge!(RablRails.xml_options)
				hash.to_xml(xml_options)
      end

      def resolve_cache_key(key, data)
        "#{super}.xml"
      end
    end
  end
end