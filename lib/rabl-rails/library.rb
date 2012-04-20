require 'singleton'

module RablRails
  class Library
    include Singleton

    def initialize
      @cached_templates = {}
    end

    def get_rendered_template(source, context)
      path = context.instance_variable_get(:@virtual_path)
      @lookup_context = context.lookup_context

      compiled_template = get_compiled_template(path, source)

      format = context.params[:format] || 'json'
      Renderers.const_get(format.upcase!).new(context).render(compiled_template)
    end

    def get_compiled_template(path, source)
      if path && RablRails.cache_templates?
        @cached_templates[path] ||= Compiler.new.compile_source(source)
        @cached_templates[path].dup
      else
        Compiler.new.compile_source(source)
      end
    end

    def get(path)
      template = @cached_templates[path]
      return template if template
      t = @lookup_context.find_template(path, [], false)
      get_compiled_template(path, t.source)
    end
  end
end