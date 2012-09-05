module RablRails
  #
  # Class that will compile RABL source code into a hash
  # representing data structure
  #
  class Compiler
    def initialize
      @i = 0
    end

    #
    # Compile from source code and return the CompiledTemplate
    # created.
    #
    def compile_source(source)
      @template = CompiledTemplate.new
      instance_eval(source)
      @template
    end

    #
    # Sets the object to be used as the data for the template
    # Example:
    #   object :@user
    #   object :@user, :root => :author
    #
    def object(data, options = {})
      @template.data, @template.root_name = extract_data_and_name(data)
      @template.root_name = options[:root] if options.has_key? :root
    end
    alias_method :collection, :object

    #
    # Includes the attribute or method in the output
    # Example:
    #   attributes :id, :name
    #   attribute :email => :super_secret
    #
    def attribute(*args)
      if args.first.is_a?(Hash)
        args.first.each_pair { |k, v| @template[v] = k }
      else
        options = args.extract_options!
        args.each { |name|
          key = options[:as] || name
          @template[key] = name
        }
      end
    end
    alias_method :attributes, :attribute

    #
    # Creates a child node to be included in the output.
    # name_or data can be an object or collection or a method to call on the data. It
    # accepts :root and :partial options.
    # Notes that partial and blocks are not compatible
    # Example:
    #   child(:@posts, :root => :posts) { attribute :id }
    #   child(:posts, :partial => 'posts/base')
    #
    def child(name_or_data, options = {})
      data, name = extract_data_and_name(name_or_data)
      name = options[:root] if options.has_key? :root
      if options[:partial]
        template = Library.instance.compile_template_from_path(options[:partial])
        @template[name] = template.merge!(:_data => data)
      elsif block_given?
        @template[name] = sub_compile(data) { yield }
      end
    end

    #
    # Glues data from a child node to the output
    # Example:
    #   glue(:@user) { attribute :name }
    #
    def glue(data)
      return unless block_given?
      name = :"_glue#{@i}"
      @i += 1
      @template[name] = sub_compile(data) { yield }
    end

    #
    # Creates an arbitrary node in the json output.
    # It accepts :if option to create conditionnal nodes. The current data will
    # be passed to the block so it is advised to use it instead of ivars.
    # Example:
    #   node(:name) { |user| user.first_name + user.last_name }
    #   node(:role, if: ->(u) { !u.admin? }) { |u| u.role }
    #
    def node(name, options = {}, &block)
      condition = options[:if]

      if condition
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

    #
    # Extends an existing rabl template
    # Example:
    #   extends 'users/base'
    #
    def extends(path)
      t = Library.instance.compile_template_from_path(path)
      @template.merge!(t.source)
    end

    #
    # Provide a conditionnal block
    #
    # condition(->(u) { u.is_a?(Admin) }) do
    #   attributes :secret
    # end
    #
    def condition(proc)
      return unless block_given?
      name = :"_if#{@i}"
      @i += 1
      @template[name] = Condition.new(proc, sub_compile(nil) { yield })
    end

    protected

    #
    # Extract data root_name and root name
    # Example:
    #   :@users -> [:@users, nil]
    #   :@users => :authors -> [:@users, :authors]
    #
    def extract_data_and_name(name_or_data)
      case name_or_data
      when Symbol
        str = name_or_data.to_s
        str.start_with?('@') ? [name_or_data, str[1..-1]] : [name_or_data, name_or_data]
      when Hash
        name_or_data.first
      else
        name_or_data
      end
    end

    def sub_compile(data)
      return {} unless block_given?
      old_template, @template = @template, {}
      yield
      data ? @template.merge!(:_data => data) : @template
    ensure
      @template = old_template
    end
  end
end