require 'singleton'

module RablRails
  class Library
    include Singleton

    def initialize
      @cached_templates = {}
    end

    def get_rendered_template(source, context, locals = nil)
      path = context.instance_variable_get(:@virtual_path)
      @lookup_context = context.lookup_context

      compiled_template = compile_template_from_source(source, path)

      format = context.params[:format] || 'json'
      Renderers.const_get(format.to_s.upcase!).new(context, locals).render(compiled_template)
    end

    def compile_template_from_source(source, path = nil)
      if path && RablRails.cache_templates?
        @cached_templates[path] ||= Compiler.new.compile_source(source)
      else
        Compiler.new.compile_source(source)
      end
    end

    def compile_template_from_path(path)
      template = @cached_templates[path]
      return template if template
      t = @lookup_context.find_template(path, [], false)
      compile_template_from_source(t.source, path)
    end
  end
end