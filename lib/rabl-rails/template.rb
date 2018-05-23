module RablRails
  class CompiledTemplate
    attr_accessor :nodes, :data, :root_name, :cache_key

    def initialize
      @nodes        = []
      @data         = nil
      @cache_key    = false
      @attrs_count  = 0
    end

    def initialize_dup(other)
      super
      self.nodes = other.nodes.dup
    end

    def add_node(n)
      @attrs_count += 1 if n.is_a?(Nodes::Attribute)
      @nodes << n
    end

    def extends(template)
      @nodes.concat template.nodes
    end

    def optimize!
      return if @attrs_count < 1

      attributes, others = @nodes.partition { |node| node.is_a?(Nodes::Attribute) }
      hash = {}
      attributes.each { |a| hash.merge!(a.hash) }

      @nodes = others.unshift(Nodes::Attribute.new(hash))
    end
  end
end
