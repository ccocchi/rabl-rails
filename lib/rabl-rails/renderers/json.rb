module RablRails
  module Renderers
    class JSON < Base
      def format_output(hash)
        ActiveSupport::JSON.encode(hash)
      end
    end
  end
end