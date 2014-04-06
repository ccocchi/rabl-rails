module RablRails
  module Renderers
    module PLIST
      include Renderers::Hash
      extend self

      def format_output(hash, options = {})
        hash = { options[:root_name] => hash } if options[:root_name] && RablRails.configuration.include_plist_root
        RablRails.configuration.plist_engine.dump(hash)
      end

      def resolve_cache_key(key, data)
        "#{super}.plist"
      end
    end
  end
end