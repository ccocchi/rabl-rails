require 'forwardable'

module RablRails
  module Nodes
    class Attribute
      extend Forwardable

      def_delegators :@hash, :[]=, :each
      attr_reader   :hash
      attr_accessor :condition

      def initialize(hash = {})
        @hash = hash
      end
    end
  end
end
