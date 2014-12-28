require 'active_support/core_ext/class/attribute'

module RablRails
  module Handlers
    class Rabl
      def self.call(template)
        %{
          RablRails::Library.instance.
            get_rendered_template(#{template.source.inspect}, self, local_assigns)
        }
      end
    end
  end
end