module RablRails
  module Nodes
    class Condition
      include Node

      attr_reader :condition, :template

      def initialize(condition, template)
        @condition = condition
        @template = template
      end
    end
  end
end