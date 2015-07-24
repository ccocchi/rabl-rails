module RablRails
  #
  # Class that will compile RABL source code into a hash
  # representing data structure
  #
  class Compiler
    def initialize(view)
      @view = view
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

    def root(name)
      @template.root_name = name
    end

    #
    # Includes the attribute or method in the output
    # Example:
    #   attributes :id, :name
    #   attribute :email => :super_secret
    #
    def attribute(*args)
      node = Nodes::Attribute.new

      if args.first.is_a?(Hash)
        args.first.each_pair { |k, v| node[v] = k }
      else
        options = args.extract_options!
        args.each { |name|
          key = options[:as] || name
          node[key] = name
        }
        node.condition = options[:if]
      end

      @template.add_node node
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

      if options.key?(:partial)
        template = Library.instance.compile_template_from_path(options[:partial], @view)
        template.data = data
      elsif block_given?
        template = sub_compile(data) { yield }
      end

      @template.add_node Nodes::Child.new(name, template)
    end

    #
    # Glues data from a child node to the output
    # Example:
    #   glue(:@user) { attribute :name }
    #
    def glue(data)
      return unless block_given?

      template = sub_compile(data) { yield }
      @template.add_node Nodes::Glue.new(template)
    end

    #
    # Creates an arbitrary node in the json output.
    # It accepts :if option to create conditionnal nodes. The current data will
    # be passed to the block so it is advised to use it instead of ivars.
    # Example:
    #   node(:name) { |user| user.first_name + user.last_name }
    #   node(:role, if: ->(u) { !u.admin? }) { |u| u.role }
    #
    def node(name = nil, options = {}, &block)
      return unless block_given?
      @template.add_node Nodes::Code.new(name, block, options[:if])
    end
    alias_method :code, :node

    #
    # Merge arbitrary data into json output. Given block should
    # return a hash.
    # Example:
    #   merge { |item| partial("specific/#{item.to_s}", object: item) }
    #
    def merge
      return unless block_given?
      node(nil) { yield }
    end

    #
    # Extends an existing rabl template
    # Example:
    #   extends 'users/base'
    #
    def extends(path)
      @template.extends Library.instance.compile_template_from_path(path, @view)
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
      @template.add_node Nodes::Condition.new(proc, sub_compile(nil, true) { yield })
    end

    def cache(&block)
      @template.cache_key = block_given? ? block : nil
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

    def sub_compile(data, only_nodes = false)
      raise unless block_given?
      old_template, @template = @template, CompiledTemplate.new
      yield
      @template.data = data
      only_nodes ? @template.nodes : @template
    ensure
      @template = old_template
    end
  end
end
