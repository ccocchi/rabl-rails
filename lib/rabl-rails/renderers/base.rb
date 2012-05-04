module RablRails
  module Renderers
    class PartialError < StandardError; end

    class Base

      def initialize(context) # :nodoc:
        @_context = context
        setup_render_context
      end

      #
      # Render a template.
      # Uses the compiled template source to get a hash with the actual
      # data and then format the result according to the `format_result`
      # method defined by the renderer.
      #
      def render(template)
        collection_or_resource = @_context.instance_variable_get(template.data) if template.data
        output_hash = collection_or_resource.respond_to?(:each) ? render_collection(collection_or_resource, template.source) :
          render_resource(collection_or_resource, template.source)
        output_hash = { template.root_name => output_hash } if template.root_name
        format_output(output_hash)
      end

      #
      # Format a hash into the desired output.
      # Renderer subclasses must implement this method
      #
      def format_output(hash)
        raise "Muse be implemented by renderer"
      end

      protected

      #
      # Render a single resource as a hash, according to the compiled
      # template source passed.
      #
      def render_resource(data, source)
        source.inject({}) { |output, current|
          key, value = current

          out = case value
          when Symbol
            data.send(value) # attributes
          when Proc
            instance_exec data, &value # node
          when Array # node with condition
            next output if !instance_exec data, &(value.first)
            instance_exec data, &(value.last)
          when Hash
            current_value = value.dup
            data_symbol = current_value.delete(:_data)
            object = data_symbol.nil? ? data : data_symbol.to_s.start_with?('@') ? @_context.instance_variable_get(data_symbol) : data.send(data_symbol)

            if key.to_s.start_with?('_') # glue
              current_value.each_pair { |k, v|
                output[k] = object.send(v)
              }
              next output
            else # child
              object.respond_to?(:each) ? render_collection(object, current_value) : render_resource(object, current_value)
            end
          end
          output[key] = out
          output
        }
      end

      #
      # Call the render_resource mtehod on each object of the collection
      # and return an array of the returned values.
      #
      def render_collection(collection, source)
        collection.map { |o| render_resource(o, source) }
      end

      #
      # Allow to use partial inside of node blocks (they are evaluated at)
      # rendering time.
      #
      def partial(template_path, options = {})
        raise PartialError.new("No object was given to partial #{template_path}") unless options[:object]
        object = options[:object]

        return [] if object.respond_to?(:empty?) && object.empty?

        template = Library.instance.get(template_path)
        object.respond_to?(:each) ? render_collection(object, template.source) : render_resource(object, template.source)
      end

      #
      # If a method is called inside a 'node' property or a 'if' lambda
      # it will be passed to context if it exists or treated as a standard
      # missing method.
      #
      def method_missing(name, *args, &block)
        @_context.respond_to?(name) ? @_context.send(name, *args, &block) : super
      end

      #
      # Copy assigns from controller's context into this
      # renderer context to include instances variables when
      # evaluating 'node' properties.
      #
      def setup_render_context
        @_context.instance_variable_get(:@_assigns).each_pair { |k, v|
          instance_variable_set("@#{k}", v) unless k.start_with?('_') || k == @data
        }
      end
    end
  end
end