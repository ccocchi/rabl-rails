module Visitors
  class Visitor
    def visit(node)
      dispatch(node)
    end

    def visit_Array a
      a.each { |n| dispatch(n) }
    end

    private

    DISPATCH = Hash.new do |hash, node_class|
      hash[node_class] = "visit_#{node_class.name.split('::').last}"
    end

    def dispatch(node)
      send DISPATCH[node.class], node
    end
  end
end
