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

      format = context.params[:format] ? context.params[:format].to_s.upcase : :JSON
      Renderers.const_get(format).render(compiled_template, context, locals)
    end

    def compile_template_from_source(source, path = nil)
      if path && RablRails.cache_templates?
        @cached_templates[path] ||= Compiler.new.compile_source(source)
        @cached_templates[path].dup
      else
        Compiler.new.compile_source(source)
      end
    end

    def compile_template_from_path(path)
      return @cached_templates[path].dup if @cached_templates.has_key?(path)

      t = @lookup_context.find_template(path, [], false)
      compile_template_from_source(t.source, path)
    end
  end
end