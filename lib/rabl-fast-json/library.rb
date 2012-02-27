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
      start = Time.now
      compiled_template = get_compiled_template(path, source, context)
      compiled_time = Time.now
      compiled_template.context = context
      r = compiled_template.render
      render_time = Time.now
      res = ActiveSupport::JSON.encode(r)
      final_time = Time.now

      Rails.logger.warn "[BENCHMARK] Compilation:\t#{(compiled_time - start) * 1000.0}ms"
      Rails.logger.warn "[BENCHMARK] Rendering:\t\t#{(render_time - compiled_time) * 1000.0}ms"
      Rails.logger.warn "[BENCHMARK] JSON encoding:\t#{(final_time - render_time) * 1000.0}ms"
      Rails.logger.warn "[BENCHMARK] Total:\t\t#{(final_time - start) * 1000.0}ms"

      res
    end

    def get_compiled_template(path, source, context)
      #@cached_templates[path] ||=
      Compiler.new(context).compile_source(source)
    end

    def get(path)
      template = @cached_templates[path]
      return template if !template.nil?
      t = @view_renderer.lookup_context.find_template(path, [], false)
      get_compiled_template(path, t.source, nil)
    end
  end
end