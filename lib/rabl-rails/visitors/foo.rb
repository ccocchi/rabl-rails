module Visitors
  class Foo < Visitor
    attr_reader :resource, :result

    def initialize(resource)
      @resource = resource
      @result = {}
    end

    def visit_Array n
      n.each { |i| visit i }
    end

    def visit_Attribute n
      n.each { |k, v| @result[k] = resource.send(v) }
    end

    def visit_Child n
      data = n.template.data
      object = data

      @result[n.name] = if object
        nodes = n.template.nodes
        object.respond_to?(:each) ? object.map { |o| sub_visit(o, nodes) } : sub_visit(object, nodes)
      else
        nil
      end
    end

    def visit_Code n
      if !n.condition || instance_exec(resource, &(n.condition))
        result = instance_exec resource, &(n.block)
        n.name ? @result[n.name] = result : @result.merge!(result)
      end
    end

    def visit_Condition n
      @resul.merge!(sub_visit(resource, n.template.nodes)) if instance_exec resource, &(n.condition)
    end

    def visit_Glue n
      @result.merge! sub_visit n.template.nodes
    end

    private

    def sub_visit(resource, nodes)
      v = self.class.new(resource)
      v.visit nodes
      v.result
    end
  end
end