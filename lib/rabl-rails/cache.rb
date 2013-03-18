module RablRails
  class Cache
    attr_reader :key, :source, :data

    def initialize(key, compiled_source)
      @key = key
      @source = compiled_source
      @data = @source.delete(:_data)
    end
  end
end