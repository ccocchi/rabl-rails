module RablRails
  module Nodes
    class Glue
      include Node

      attr_reader :template

      def initialize(template)
        @template = template
        @is_var   = template.data.to_s.start_with?('@')
      end

      def data
        @template.data
      end

      def nodes
        @template.nodes
      end

      def instance_variable_data?
        @is_var
      end
    end
  end
end
