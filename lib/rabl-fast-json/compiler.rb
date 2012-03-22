module RablFastJson
  class Compiler
    include Helpers

    def initialize(context = nil)
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
      data, name = extract_data_and_name(name_or_data)
      name = options[:root] if root_given?(options)
      if partial_given?(options)
        template = Library.instance.get(options[:partial], @context)
        @template[name] = template.merge!(:_data => data)
      else
        _compile_sub_template(name, data, &block)
      end
    end

    def glue(data, &block)
      return unless block_given?
      name = :"_glue#{@glue_count}"
      @glue_count += 1
      _compile_sub_template(name, data, &block)
    end

    def node(name, options = {}, &block)
      condition = options[:if]

      if condition.present?
        if condition.is_a?(Proc)
          @template[name] = [condition, block]
        else
          @template[name] = block if condition
        end
      else
        @template[name] = block
      end
    end
    alias_method :code, :node

    def collection(data, options = {})
      object(data)
      @template.root_name = options[:root] if root_given?(options)
    end

    def extends(path)
      t = Library.instance.get(path, @context)
      @template.merge!(t.source)
    end

    def object(data)
      return if data === false
      data, name = extract_data_and_name(data)
      @template.data, @template.root_name = data, name
    end

    protected

    def extract_data_and_name(name_or_data)
      case name_or_data
      when Symbol
        if name_or_data.to_s.start_with?('@')
          [name_or_data, nil]
        else
          [name_or_data, name_or_data]
        end
      when Hash
        name_or_data.first
      else
        name_or_data
      end
    end

    def _compile_sub_template(name, data, &block)
      compiler = Compiler.new(@context)
      template = compiler.compile_block(&block)
      @template[name] = template.merge!(:_data => data)
    end
  end
end