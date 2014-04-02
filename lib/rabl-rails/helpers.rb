module RablRails
  module Helpers
    def collection?(resource)
      resource && resource.respond_to?(:each) && !resource.is_a?(Struct)
    end
  end
end