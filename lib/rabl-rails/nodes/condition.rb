module RablRails
  module Nodes
    class Condition
      include Node

      attr_reader :condition, :nodes

      def initialize(condition, nodes)
        @condition = condition
        @nodes = nodes
      end
    end
  end
end