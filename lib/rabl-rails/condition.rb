module RablRails
  class Condition
    attr_reader :proc, :source

    def initialize(proc, source)
      @proc = proc
      @source = source
    end
  end
end