module RablRails
  module Renderers
    class JSON < Base
      def format_output(hash)
        hash = { _options[:root_name] => hash } if _options[:root_name] && RablRails.include_json_root
        MultiJson.encode(hash)
      end
    end
  end
end