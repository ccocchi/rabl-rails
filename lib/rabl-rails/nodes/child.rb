module Nodes
  class Child
    include Node

    attr_reader :name, :template

    def initialize(name, template)
      @name = name
      @template = template
    end
  end
end