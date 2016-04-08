module RablRails
  module Nodes
    class Extend
      attr_reader :nodes, :locals

      def initialize(nodes, locals)
        @nodes  = nodes
        @locals = locals
      end
    end
  end
end
