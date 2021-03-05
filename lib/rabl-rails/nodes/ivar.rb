module RablRails::Nodes
  #IVar = Struct.new(:name, :vname)
  class IVar
    attr_reader :name, :vname

    def initialize(name, vname)
      @name   = name
      @vname  = vname
    end
  end
end
