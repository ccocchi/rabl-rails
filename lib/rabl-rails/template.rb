module RablRails
  class CompiledTemplate
    attr_accessor :source, :data, :root_name

    delegate :[], :[]=, :merge!, :to => :source

    def initialize
      @source = {}
    end

    def initialize_dup(other)
      super
      self.source = other.source.dup
    end
  end
end