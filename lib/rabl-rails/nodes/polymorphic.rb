module RablRails
  module Nodes
    class Polymorphic
      attr_reader :template_lambda

      def initialize(template_lambda)
        @template_lambda = template_lambda
      end
    end
  end
end
