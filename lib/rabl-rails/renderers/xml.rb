module RablRails
  module Renderers
    class XML < Base
    	DEFAULT_OPTIONS = { dasherize: true, skip_types: false }

      def format_output(hash)
      	# hash = hash[options[:root_name]] if options[:root_name]
      	xml_options = { root: options[:root_name] }.merge!(DEFAULT_OPTIONS)
				hash.to_xml(xml_options)
      end
    end
  end
end