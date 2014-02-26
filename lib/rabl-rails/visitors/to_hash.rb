module Visitors
  class ToHash < Visitor
    attr_reader :_resource, :_result

    class PartialError < StandardError; end

    def initialize(view_context, resource = nil)
      @_context  = view_context
      @_result   = {}
      @_resource = resource

      copy_instance_variables_from_context
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
      object = object_from_data(_resource, n.data, n.instance_variable_data?)

      @_result[n.name] = if object
        object.respond_to?(:each) ? object.map { |o| sub_visit(o, n.nodes) } : sub_visit(object, n.nodes)
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
      object = object_from_data(_resource, n.data, n.instance_variable_data?)
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

      template = RablRails::Library.instance.compile_template_from_path(template_path)
      if object.respond_to?(:each)
        object.map { |o| sub_visit o, template.nodes }
      else
        sub_visit object, template.nodes
      end
    end

    private

    def copy_instance_variables_from_context
      @_context.instance_variable_get(:@_assigns).each_pair { |k, v|
        instance_variable_set("@#{k}", v) unless k.to_s.start_with?('_')
      }
    end

    def sub_visit(resource, nodes)
      old_result, old_resource, @_result = @_result, @_resource, {}
      reset_for resource
      visit nodes
      _result
    ensure
      @_result, @_resource = old_result, old_resource
    end

    def object_from_data(resource, symbol, is_variable)
      return resource if symbol == nil

      if is_variable
        @_context.instance_variable_get(symbol)
      else
        resource.respond_to?(symbol) ? resource.send(symbol) : @_context.send(symbol)
      end
    end
  end
end