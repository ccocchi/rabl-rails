module RablFastJson
  module Handlers
    class Rabl
      cattr_accessor :default_format
      self.default_format = 'application/json'

      def self.call(template)
        %{
          RablFastJson::Compiler.instance.compile_source(#{template.source.inspect}, self)
        }
      end
    end
  end
end