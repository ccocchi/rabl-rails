module RablRails
  module Renderers
    class JSON < Base
      def format_output(hash)
        hash = { options[:root_name] => hash } if options[:root_name] && RablRails.include_json_root
        ActiveSupport::JSON.encode(hash)
      end
    end
  end
end