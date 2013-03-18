module RablRails
  module Renderers
    class JSON < Base
      def format_output(hash)
        hash = { _options[:root_name] => hash } if _options[:root_name] && RablRails.include_json_root
        json = MultiJson.encode(hash)

        RablRails.enable_jsonp_callbacks && params.has_key?(:callback) ? "#{params[:callback]}(#{json})" : json
      end

      def resolve_cache_key(data, key)
        "#{super}.json"
      end
    end
  end
end