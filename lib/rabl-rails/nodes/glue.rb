module RablRails
  module Nodes
    class Glue
      include Node

      attr_reader :template

      def initialize(template)
        @template = template
      end

      def data
        @template.data
      end

      def nodes
        @template.nodes
      end

      def instance_variable_data?
        @instance_variable_data ||= data.to_s.start_with?('@')
      end
    end
  end
end