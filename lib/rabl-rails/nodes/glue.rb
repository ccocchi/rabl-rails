module Nodes
  class Glue
    include Node

    def initialize(template)
      @template = template
    end
  end
end