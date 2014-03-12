module RablRails
  module Nodes
    class Child < Glue
      attr_reader :name

      def initialize(name, template)
        super(template)
        @name = name
      end
    end
  end
end