module RablRails
  module Nodes
    class Lookup
      attr_reader :name, :data, :field

      def initialize(name, data, field, cast = false)
        @name   = name
        @data   = data
        @field  = field
        @cast   = cast
        @is_var = @data.to_s.start_with?('@')
      end

      def instance_variable_data?
        @is_var
      end

      def cast_to_boolean?
        @cast
      end
    end
  end
end
