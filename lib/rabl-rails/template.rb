module RablRails
  class CompiledTemplate
    attr_accessor :source, :data, :root_name

    delegate :[], :[]=, :merge!, :to => :source

    def initialize
      @source = {}
    end
  end
end