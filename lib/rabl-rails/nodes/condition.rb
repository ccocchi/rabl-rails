module RablRails
  module Nodes
    class Condition
      attr_reader :condition, :nodes

      def initialize(condition, nodes)
        @condition = condition
        @nodes = nodes
      end
    end
  end
end
