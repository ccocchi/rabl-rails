module RablRails
  module Nodes
    class Code
      attr_reader :name, :block, :condition

      def initialize(name, block, condition = nil)
        @name = name
        @block = block
        @condition = condition
      end

      def merge?
        !name
      end
    end
  end
end
