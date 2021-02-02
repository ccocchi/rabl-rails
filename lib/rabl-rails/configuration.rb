require 'set'

module RablRails
  class Configuration
    attr_accessor :json_engine, :include_json_root, :enable_jsonp_callbacks
    attr_accessor :xml_options
    attr_accessor :plist_engine, :include_plist_root
    attr_accessor :cache_templates
    attr_accessor :replace_nil_values_with_empty_strings
    attr_accessor :replace_empty_string_values_with_nil
    attr_accessor :exclude_nil_values
    attr_accessor :non_collection_classes

    def initialize
      @json_engine            = defined?(::Oj) ? ::Oj : ::JSON
      @include_json_root      = true
      @enable_jsonp_callbacks = false

      @xml_options = { dasherize: true, skip_types: false }

      @plist_engine       = defined?(::Plist) ? ::Plist::Emit : nil
      @include_plist_root = false

      @cache_templates    = ActionController::Base.perform_caching

      @replace_nil_values_with_empty_strings  = false
      @replace_empty_string_values_with_nil   = false
      @exclude_nil_values                     = false

      @non_collection_classes = Set.new(['Struct'])
    end

    def result_flags
      @result_flags ||= begin
        result = 0
        result |= 0b001   if @replace_nil_values_with_empty_strings
        result |= 0b010   if @replace_empty_string_values_with_nil
        result |= 0b100   if @exclude_nil_values
        result
      end
    end
  end
end
