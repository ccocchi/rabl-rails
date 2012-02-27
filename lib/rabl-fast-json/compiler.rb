module RablFastJson
  class Compiler

    def initialize(context = nil, assigns = nil)
      @context = context
      @glue_count = 0
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
      object(data)
    end

    def extends(path)
      t = Library.instance.get(path)
      @template.merge!(t.source)
    end

    def object(data)
      data, name = extract_data_and_name(data)
      @template.data, @template.root_name = data, name
    end

    def method_missing(name, *args, &block)
      @context.respond_to?(name) ? @context.send(name, *args, &block) : super
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
  end
end