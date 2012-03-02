module RablFastJson
  module Helpers
    def root_given?(options)
      options[:root].present?
    end

    def partial_given?(options)
      options[:partial].present?
    end
  end
end