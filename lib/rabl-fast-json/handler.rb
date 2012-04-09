module RablFastJson
  module Handlers
    class Rabl
      cattr_accessor :default_format
      self.default_format = 'application/json'

      def self.call(template)
        %{
          RablFastJson::Library.instance.
            get_rendered_template(#{template.source.inspect}, self)
        }
      end
    end
  end
end