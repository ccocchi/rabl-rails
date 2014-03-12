module RablRails
  module Nodes
    module Node
      def accept(visitor)
        visitor.visit(self)
      end
    end
  end
end