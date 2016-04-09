module RablRails
  module Nodes
    class Attribute
      attr_reader   :hash
      attr_accessor :condition

      def initialize(hash = {})
        @hash = hash
      end

      def []=(key, value)
        @hash[key] = value
      end

      def each(&block)
        @hash.each(&block)
      end
    end
  end
end
