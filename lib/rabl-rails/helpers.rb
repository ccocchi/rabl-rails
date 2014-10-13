module RablRails
  module Helpers
    def collection?(resource)
      klass = resource.class

      resource && resource.respond_to?(:each) &&
        RablRails.configuration.non_collection_classes.none? { |k| klass <= k }
    end
  end
end