require 'singleton'

module RablFastJson
  class Compiler

    def initialize(context, assigns = nil)
      @context = context
      @glue_count = 0
      _get_assigns_from_context(assigns)
      _get_virtual_path_from_context
    end

    def compile_source(source)
      @template = CompiledTemplate.new
      instance_eval(source)
      @template
    end

    def compile_block(&block)
      @template = {}
      instance_eval(&block)
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

    def child(name_or_data, options = {}, &block)
      return unless block_given?
      data, name = extract_data_and_name(name_or_data)
      _compile_sub_template(name, data, &block)
    end

    def glue(data, &block)
      return unless block_given?
      name = :"_glue#{@glue_count}"
      @glue_count += 1
      _compile_sub_template(name, data, &block)
    end

    def node(name, options = {}, &block)
      @template[name] = block
    end
    alias_method :code, :node

    def collection(data, options = {})
      @data = data.to_a if data
    end

    def object(data)
      data, name = extract_data_and_name(data)
      @template.data, @template.root_name = data, name
    end

    protected

    def extract_data_and_name(name_or_data)
      case name_or_data
      when Symbol
        [name_or_data, name_or_data]
      when Hash
        name_or_data.first
      else
        name_or_data
      end
    end

    def _compile_sub_template(name, data, &block)
      compiler = Compiler.new(@context, @assigns)
      template = compiler.compile_block(&block)
      @template[name] = template.merge!(:_data => data)
    end

    def _get_assigns_from_context(assigns)
      source = assigns || @context.instance_variable_get(:@_assigns)
      source.each_pair { |k, v|
        instance_variable_set("@#{k}", v) unless k.start_with?('_')
      }
    end

    def _get_virtual_path_from_context
      @virtual_path = @context.instance_variable_get(:@virtual_path)
    end
  end
end