module RablRails
  class CompiledTemplate
    attr_accessor :source, :data, :root_name, :cache_key

    delegate :[], :[]=, :merge!, :to => :source

    def initialize
      @source = {}
      @cache_key = false
    end

    def initialize_dup(other)
      super
      self.source = other.source.dup
    end
  end
end