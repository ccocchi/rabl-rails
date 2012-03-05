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
      data ||= @object
      source ||= @source

      source.inject({}) { |output, current|
        key, value = current

        out = case value
        when Symbol
          data.send(value) # attributes
        when Proc
          value.call(data) # node
        when Array # node with condition
          next output if !value.first.call(data)
          value.last.call(data)
        when Hash
          current_value = value.dup
          data_symbol = current_value.delete(:_data)
          object = data_symbol.nil? ? data : data_symbol.to_s.start_with?('@') ? @context.instance_variable_get(data_symbol) : data.send(data_symbol)

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

    def render_collection(collection = nil, source = nil)
      collection ||= @object
      collection.inject([]) { |output, o| output << render_resource(o, source) }
    end
  end
end