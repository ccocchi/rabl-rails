require 'singleton'
require 'monitor'
require 'thread_safe'

module RablRails
  class Library
    include Singleton

    RENDERER_MAP = {
      'json'  => Renderers::JSON,
      'xml'   => Renderers::XML,
      'ruby'  => Renderers::Hash,
      'plist' => Renderers::PLIST
    }.freeze

    def initialize
      @cached_templates = ThreadSafe::Cache.new
      @mutex = Monitor.new
    end

    def reset_cache!
      @cached_templates = ThreadSafe::Cache.new
    end

    def get_rendered_template(source, view, locals = nil)
      compiled_template = compile_template_from_source(source, view)
      format = retrieve_format_from_view(view)
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

    def retrieve_format_from_view(view)
      return view.params[:format].to_s.downcase if view.params.key?(:format)

      if view.respond_to?(:request)
        view.request.format.to_sym.to_s
      else
        'json'
      end
    end

    def synchronized_compile(path, source, view)
      @cached_templates[path] || @mutex.synchronize do
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
      view.lookup_context.find_template(path, [], false).source
    end
  end
end