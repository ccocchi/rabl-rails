module RablRails
  module Renderers
    class PLIST < Base

      def format_output(hash)
        hash = { _options[:root_name] => hash } if _options[:root_name] && RablRails.include_plist_root
        RablRails.plist_engine.dump(hash)
      end
    end
  end
end