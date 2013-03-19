module RablRails
  module Renderers
    class PLIST < Base

      def format_output(hash)
        hash = { _options[:root_name] => hash } if _options[:root_name] && RablRails.include_plist_root
        RablRails.plist_engine.dump(hash)
      end

      def resolve_cache_key(key, data)
        "#{super}.xml"
      end
    end
  end
end