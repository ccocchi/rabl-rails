require 'singleton'
require 'monitor'

module RablRails
  class Library
    include Singleton

    UnknownFormat = Class.new(StandardError)

    RENDERER_MAP = {
      json:   Renderers::JSON,
      xml:    Renderers::XML,
      ruby:   Renderers::Hash,
      plist:  Renderers::PLIST
    }.freeze

    def initialize
      @cached_templates = {}
      @monitor = Monitor.new
    end

    def reset_cache!
      @cached_templates = {}
    end

    def get_rendered_template(source, view, locals = nil)
      compiled_template = compile_template_from_source(source, view)
      format = view.lookup_context.rendered_format || :json
      raise UnknownFormat, "#{format} is not supported in rabl-rails" unless RENDERER_MAP.key?(format)
      RENDERER_MAP[format].render(compiled_template, view, locals)
    end

    def compile_template_from_source(source, view)
      if RablRails.configuration.cache_templates
        path = view.instance_variable_get(:@virtual_path)
        synchronized_compile(path, source, view)
      else
        compile(source, view)
      end
    end

    def compile_template_from_path(path, view)
      if RablRails.configuration.cache_templates
        synchronized_compile(path, nil, view)
      else
        source = fetch_source(path, view)
        compile(source, view)
      end
    end

    private

    def synchronized_compile(path, source, view)
      @cached_templates[path] || @monitor.synchronize do
        # Any thread holding this lock will be compiling the template needed
        # by the threads waiting. So re-check the template presence to avoid
        # re-compilation
        @cached_templates.fetch(path) do
          source ||= fetch_source(path, view)
          @cached_templates[path] = compile(source, view)
        end
      end
    end

    def compile(source, view)
      Compiler.new(view).compile_source(source)
    end

    def fetch_source(path, view)
      t = view.lookup_context.find_template(path, [], false)
      t = t.refresh(view) unless t.source
      t.source
    end
  end
end
