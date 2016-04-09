module RablRails
  module Renderers
    module Hash
      include ::RablRails::Helpers
      extend self

      #
      # Render a template.
      # Uses the compiled template source to get a hash with the actual
      # data and then format the result according to the `format_result`
      # method defined by the renderer.
      #
      def render(template, context, locals = nil)
        visitor = Visitors::ToHash.new(context)

        collection_or_resource = if template.data
          if context.respond_to?(template.data)
            context.send(template.data)
          else
            visitor.instance_variable_get(template.data)
          end
        end

        render_with_cache(template.cache_key, collection_or_resource) do
          output_hash = if collection?(collection_or_resource)
            render_collection(collection_or_resource, template.nodes, visitor)
          else
            render_resource(collection_or_resource, template.nodes, visitor)
          end

          format_output(output_hash, root_name: template.root_name, params: context.params)
        end
      end

      protected

      #
      # Format a hash into the desired output.
      # Renderer subclasses must implement this method
      #
      def format_output(hash, options = {})
        hash = { options[:root_name] => hash } if options[:root_name]
        hash
      end

      private

      #
      # Render a single resource as a hash, according to the compiled
      # template source passed.
      #
      def render_resource(resource, nodes, visitor)
        visitor.reset_for resource
        visitor.visit nodes
        visitor.result
      end

      #
      # Call the render_resource mtehod on each object of the collection
      # and return an array of the returned values.
      #
      def render_collection(collection, nodes, visitor)
        collection.map { |o| render_resource(o, nodes, visitor) }
      end

      def resolve_cache_key(key, data)
        return data.cache_key unless key
        key.is_a?(Proc) ? instance_exec(data, &key) : key
      end

      private

      def render_with_cache(key, collection_or_resource)
        if !key.is_a?(FalseClass) && ActionController::Base.perform_caching
          Rails.cache.fetch(resolve_cache_key(key, collection_or_resource)) do
            yield
          end
        else
          yield
        end
      end
    end
  end
end
