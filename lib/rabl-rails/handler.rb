require 'active_support/core_ext/class/attribute'

module RablRails
  module Handlers
    class Rabl
      def self.call(template, source = nil)
        %{
          RablRails::Library.instance.
            get_rendered_template(#{(source || template.source).inspect}, self, local_assigns)
        }
      end
    end
  end
end
