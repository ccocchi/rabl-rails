module RablFastJson
  class CompiledTemplate
    attr_accessor :source, :data, :root_name, :context

    delegate :[], :[]=, :merge!, :to => :source

    def initialize
      @source = {}
    end
    
    def has_root_name?
      !@root_name.nil?
    end

    def render
      get_object_from_context
      get_assigns_from_context
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
          instance_exec data, &value # node
        when Array # node with condition
          next output if !instance_exec data, &(value.first) #value.first.call(data)
          instance_exec data, &(value.last)
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
    
    def method_missing(name, *args, &block)
      @context.respond_to?(name) ? @context.send(name, *args, &block) : super
    end
    
    def partial(template_path, options = {})      
      raise "No object was given to partial" if options[:object].nil?
      object = options[:object]

      return [] if object.respond_to?(:empty?) && object.empty?
      
      template = Library.instance.get(template_path)
      object.respond_to?(:each) ? template.render_collection(object) : template.render_resource(object)
    end
    
    protected
    
    def get_object_from_context
      @object = @context.instance_variable_get(@data) if @data
    end
    
    def get_assigns_from_context
      @context.instance_variable_get(:@_assigns).each_pair { |k, v|
        instance_variable_set("@#{k}", v) unless k.start_with?('_') || k == @data
      }
    end  
  end
end