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
    # Note that partial and blocks are not compatible
    # Example:
    #   child(:@posts, :root => :posts) { attribute :id }
    #   child(:posts, :partial => 'posts/base')
    #
    def child(name_or_data, options = {})
      data, name  = extract_data_and_name(name_or_data)
      name        = options[:root]  if options.has_key? :root
      name        = options[:as]    if options.has_key? :as
      template    = partial_or_block(data, options) { yield }
      @template.add_node Nodes::Child.new(name, template)
    end

    #
    # Glues data from a child node to the output
    # Example:
    #   glue(:@user) { attribute :name }
    #
    def glue(data, options = {})
      template = partial_or_block(data, options) { yield }
      @template.add_node Nodes::Glue.new(template)
    end

    #
    # Creates a node to be added to the output by fetching an object using
    # current resource's field as key to the data, and appliying given
    # template to said object
    # Example:
    #   fetch(:@stats, field: :id) { attributes :total }
    #
    def fetch(name_or_data, options = {})
      data, name  = extract_data_and_name(name_or_data)
      name        = options[:as] if options.key?(:as)
      field       = options.fetch(:field, :id)
      template    = partial_or_block(data, options) { yield }
      @template.add_node Nodes::Fetch.new(name, template, field)
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
    # Creates a constant node in the json output.
    # Example:
    #   const(:locale, 'fr_FR')
    #
    def const(name, value)
      @template.add_node Nodes::Const.new(name, value)
    end

    #
    # Create a node `name` by looking the current resource being rendered in the
    # `object` hash using, by default, the resource's id.
    # Example:
    #   lookup(:favorite, :@user_favorites, cast: true)
    #
    def lookup(name, object, field: :id, cast: false)
      @template.add_node Nodes::Lookup.new(name, object, field, cast)
    end

    #
    # Merge arbitrary data into json output. Given block should
    # return a hash.
    # Example:
    #   merge { |item| partial("specific/#{item.to_s}", object: item) }
    #
    def merge(opts = {})
      return unless block_given?
      node(nil, opts) { yield }
    end

    #
    # Extends an existing rabl template
    # Example:
    #   extends 'users/base'
    #   extends ->(item) { "v1/#{item.class}/_core" }
    #   extends 'posts/base', locals: { hide_comments: true }
    #
    def extends(path_or_lambda, options = nil)
      if path_or_lambda.is_a?(Proc)
        @template.add_node Nodes::Polymorphic.new(path_or_lambda)
        return
      end

      other = Library.instance.compile_template_from_path(path_or_lambda, @view)

      if options && options.is_a?(Hash)
        @template.add_node Nodes::Extend.new(other.nodes, options[:locals])
      else
        @template.extends(other)
      end
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
    alias_method :_if, :condition

    def cache(&block)
      @template.cache_key = block_given? ? block : nil
    end

    protected

    def partial_or_block(data, options)
      if options&.key?(:partial)
        template = Library.instance.compile_template_from_path(options[:partial], @view)
        template.data = data
        template
      elsif block_given?
        sub_compile(data) { yield }
      end
    end

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
