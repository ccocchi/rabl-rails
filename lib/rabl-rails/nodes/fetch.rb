module RablRails
  module Nodes
    class Fetch < Child
      attr_reader :field

      def initialize(name, template, field)
        super(name, template)
        @field = field
      end
    end
  end
end
