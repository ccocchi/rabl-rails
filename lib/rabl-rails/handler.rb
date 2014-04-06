require 'active_support/core_ext/class/attribute'

module RablRails
  module Handlers
    class Rabl
      class_attribute :default_format
      self.default_format = 'application/json'

      def self.call(template)
        %{
          RablRails::Library.instance.
            get_rendered_template(#{template.source.inspect}, self, local_assigns)
        }
      end
    end
  end
end