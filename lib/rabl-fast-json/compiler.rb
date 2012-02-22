require 'singleton'

module RablFastJson
  class Compiler

    def initialize(context)
      @context = context
      _get_assigns_from_context
      _get_virtual_path_from_context
    end

    def compile_source(source)
      @template = CompiledTemplate.new
      instance_eval(source)
      @template
    end

    def attribute(*args)
      if args.first.is_a?(Hash)
        args.first.each_pair { |k, v| @template[v] = k }
      else
        args.each { |name| @template[name] = name }
      end
    end
    alias_method :attributes, :attribute

    def collection(data, options = {})
      @data = data.to_a if data
    end

    def object(data)
      @data = data
    end

    protected

    def _get_assigns_from_context
      @context.instance_variable_get(:@_assigns).each_pair { |k, v|
        instance_variable_set("@#{k}", v) unless k.start_with?('_')
      }
    end

    def _get_virtual_path_from_context
      @virtual_path = @context.instance_variable_get(:@virtual_path)
    end
  end
end