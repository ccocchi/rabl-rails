module RablRails
  class CompiledTemplate
    attr_accessor :nodes, :data, :root_name, :cache_key

    def initialize
      @nodes      = []
      @data       = nil
      @cache_key  = false
    end

    def initialize_dup(other)
      super
      self.nodes = other.nodes.dup
    end

    def add_node(n)
      @nodes << n
    end

    def extends(template)
      @nodes.concat template.nodes
    end
  end
end
