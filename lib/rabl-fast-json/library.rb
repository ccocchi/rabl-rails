require 'singleton'

module RablFastJson
  class Library
    include Singleton

    attr_accessor :view_renderer

    def initialize
      @cached_templates = {}
    end

    def get_rendered_template(source, context)
      path = context.instance_variable_get(:@virtual_path)
      @view_renderer = context.instance_variable_get(:@view_renderer)

      compiled_template = get_compiled_template(path, source)
      compiled_template.context = context
      body = compiled_template.render
      ActiveSupport::JSON.encode(compiled_template.root_name ? { compiled_template.root_name => body } : body)
    end

    def get_compiled_template(path, source)
      if path && RablFastJson.cache_templates?
        @cached_templates[path] ||= Compiler.new.compile_source(source)
        @cached_templates[path].dup
      else
        Compiler.new.compile_source(source)
      end
    end

    def get(path)
      template = @cached_templates[path]
      return template unless template.nil?
      t = @view_renderer.lookup_context.find_template(path, [], false)
      get_compiled_template(path, t.source)
    end
  end
end