module RablRails
  module Helpers
    def collection?(resource)
      klass = resource.class

      resource && resource.respond_to?(:each) && resource.kind_of?(Enumerable) &&
        klass.ancestors.none? { |a| RablRails.configuration.non_collection_classes.include? a.name }
    end
  end
end