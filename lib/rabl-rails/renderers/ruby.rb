module RablRails
  module Renderers
    class RUBY < Base
      def format_output(hash)
        hash = { _options[:root_name] => hash } if _options[:root_name] && RablRails.include_json_root

        hash
      end

      def resolve_cache_key(key, data)
        "#{super}.ruby"
      end
    end
  end
end

