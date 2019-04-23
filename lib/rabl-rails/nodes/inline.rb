module RablRails
  module Nodes
    class Inline
      attr_reader :name, :inline_var

      def initialize(name, inline_var)
        @name       = name
        @inline_var = inline_var
      end
    end
  end
end
