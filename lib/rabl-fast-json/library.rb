require 'singleton'

module RablFastJson
  class Library
    include Singleton

    def initialize
      @cached_templates = {}
    end

    def get_rendered_template(source, context)
      path = context.instance_variable_get(:@virtual_path)
      @view_renderer = context.instance_variable_get(:@view_renderer)

      compiled_template = get_compiled_template(path, source, context)
      compiled_template.context = context

      ActiveSupport::JSON.encode(compiled_template.render)
    end

    def get_compiled_template(path, source, context)
      @cached_templates[path] ||= Compiler.new(context).compile_source(source)
    end

    def get(path, context)
      template = @cached_templates[path]
      return template if !template.nil?
      t = @view_renderer.lookup_context.find_template(path, [], false)
      get_compiled_template(path, t.source, context)
    end
  end
end