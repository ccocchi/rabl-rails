module RablRails
  module Nodes
    class Glue
      attr_reader :nodes, :data

      def initialize(template)
        @nodes  = template.nodes
        @data   = template.data
        @is_var = @data.to_s.start_with?('@')
      end

      def instance_variable_data?
        @is_var
      end
    end
  end
end
