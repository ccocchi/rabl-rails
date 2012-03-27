module RablFastJson
  module Helpers
    def root_given?(options) #:nodoc:
      options[:root].present?
    end

    def partial_given?(options) #:nodoc:
      options[:partial].present?
    end
  end
end