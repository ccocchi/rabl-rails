module RablFastJson
  class CompiledTemplate

    attr_accessor :source, :data, :root_name, :context

    delegate :[], :[]=, :merge!, :to => :source

    def initialize
      @source = {}
    end

    def get_object_from_assigns
      @object = @context.instance_variable_get(@data)
    end

    def render
      get_object_from_assigns
      @object.respond_to?(:each) ? render_collection : render_resource
    end

    def render_resource(data = nil, source = nil)
      output = {}

      data ||= @object
      source ||= @source

      source.each_pair { |key, value|
        out = case value
        when Symbol
          data.send(value) # attributes
        when Proc
          value.call(data) # node
        when Hash
          data_symbol = value.delete(:_data)
          object = data_symbol.to_s.start_with?('@') ? @context.instance_variable_get(data_symbol) : @object.send(data_symbol)
          if key.to_s.start_with?('_') # glue
            value.each_pair { |k, v|
              output[k] = object.send(v)
            }

            next
          else # child
            object.respond_to?(:each) ? render_collection(object, value) : render_resource(object, value)
          end
        end
        output[key] = out
      }
      output
    end

    def render_collection(collection = nil, source = nil)
      output = []
      collection ||= @object
      collection.each { |o| output << render_resource(o, source) }
      output
    end
  end
end