module Visitors
  class ToHash < Visitor
    attr_reader :_resource, :_result

    class PartialError < StandardError; end

    def initialize(view_context, resource = nil)
      @_context  = view_context
      copy_instance_variables_from_context

      @_result   = {}
      @_resource = resource
    end

    def reset_for(resource)
      @_resource = resource
      @_result = {}
    end

    def visit_Array n
      n.each { |i| visit i }
    end

    def visit_Attribute n
      n.each { |k, v| @_result[k] = _resource.send(v) }
    end

    def visit_Child n
      data = n.template.data
      object = object_from_data(_resource, data)

      @_result[n.name] = if object
        nodes = n.template.nodes
        object.respond_to?(:each) ? object.map { |o| sub_visit(o, nodes) } : sub_visit(object, nodes)
      else
        nil
      end
    end

    def visit_Code n
      if !n.condition || instance_exec(_resource, &(n.condition))
        result = instance_exec _resource, &(n.block)
        n.name ? @_result[n.name] = result : @_result.merge!(result)
      end
    end

    def visit_Condition n
      @_result.merge!(sub_visit(_resource, n.template.nodes)) if instance_exec _resource, &(n.condition)
    end

    def visit_Glue n
      object = object_from_data(_resource, n.template.data)
      @_result.merge! sub_visit(object, n.template.nodes)
    end

    protected

    #
    # If a method is called inside a 'node' property or a 'if' lambda
    # it will be passed to context if it exists or treated as a standard
    # missing method.
    #
    def method_missing(name, *args, &block)
      @_context.respond_to?(name) ? @_context.send(name, *args, &block) : super
    end

    #
    # Allow to use partial inside of node blocks (they are evaluated at
    # rendering time).
    #
    def partial(template_path, options = {})
      raise PartialError.new("No object was given to partial #{template_path}") unless options[:object]
      object = options[:object]

      return [] if object.respond_to?(:empty?) && object.empty?

      template = Library.instance.compile_template_from_path(template_path)
      object.respond_to?(:each) ? render_collection(object, template.source) : render_resource(object, template.source)
    end

    private

    def copy_instance_variables_from_context
      @_context.instance_variable_get(:@_assigns).each_pair { |k, v|
        instance_variable_set("@#{k}", v) unless k.to_s.start_with?('_')
      }
    end

    def sub_visit(resource, nodes)
      old_result, @_result = @_result, {}
      reset_for resource
      visit nodes
      _result
    ensure
      @_result = old_result
    end

    def object_from_data(resource, symbol)
      return data if symbol == nil

      if symbol.to_s.start_with?('@')
        @_context.instance_variable_get(symbol)
      else
        data.respond_to?(symbol) ? data.send(symbol) : @_context.send(symbol)
      end
    end
  end
end