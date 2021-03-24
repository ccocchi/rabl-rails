require 'helper'
require 'pathname'
require 'tmpdir'

class TestCompiler < Minitest::Test
  @@tmp_path = Pathname.new(Dir.mktmpdir)

  File.open(@@tmp_path + 'user.rabl', 'w') do |f|
    f.puts %q{
      attributes :id
    }
  end

  @@view_class = if ActionView::Base.respond_to?(:with_empty_template_cache)
    # From Rails 6.1
    ActionView::Base.with_empty_template_cache
  else
    ActionView::Base
  end

  describe 'compiler' do
    def extract_attributes(nodes)
      nodes.map(&:hash)
    end

    before do
      @view     = @@view_class.new(ActionView::LookupContext.new(@@tmp_path), {}, nil)
      @compiler = RablRails::Compiler.new(@view)
    end

    it "returns a compiled template instance" do
      assert_instance_of RablRails::CompiledTemplate, @compiler.compile_source("")
    end

    describe '#object' do
      it "sets data for the template" do
        t = @compiler.compile_source(%{ object :@user })
        assert_equal :@user, t.data
        assert_equal([], t.nodes)
      end

      it "can define root name" do
        t = @compiler.compile_source(%{ object :@user => :author })
        assert_equal :@user, t.data
        assert_equal :author, t.root_name
        assert_equal([], t.nodes)
      end
    end

    describe '#root' do
      it "defines root via keyword" do
        t = @compiler.compile_source(%{ root :author })
        assert_equal :author, t.root_name
      end

      it "overrides object root" do
        t = @compiler.compile_source(%{ object :@user ; root :author })
        assert_equal :author, t.root_name
      end

      it "can set root to false via options" do
        t = @compiler.compile_source(%( object :@user, root: false))
        assert_equal false, t.root_name
      end
    end

    describe '#collection' do
      it "sets the data for the template" do
        t = @compiler.compile_source(%{ collection :@user })
        assert_equal :@user, t.data
        assert_equal([], t.nodes)
      end

      it "can define root name" do
        t = @compiler.compile_source(%{ collection :@user => :users })
        assert_equal :@user, t.data
        assert_equal :users, t.root_name
        assert_equal([], t.nodes)
      end

      it "can define root name via options" do
        t = @compiler.compile_source(%{ collection :@user, :root => :users })
        assert_equal :@user, t.data
        assert_equal :users, t.root_name
      end
    end

    it "should not have a cache key if cache is not enable" do
      t = @compiler.compile_source('')
      assert_equal false, t.cache_key
    end

    describe '#cache' do
      it "can take no argument" do
        t = @compiler.compile_source(%{ cache })
        assert_nil t.cache_key
      end

      it "sets the given block as cache key" do
        t = @compiler.compile_source(%( cache { 'foo' }))
        assert_instance_of Proc, t.cache_key
      end
    end

    # Compilation

    it "compiles single attributes" do
      t = @compiler.compile_source(%{ attributes :id, :name })
      assert_equal([{ :id => :id, :name => :name }], extract_attributes(t.nodes))
    end

    it "compiles attributes with the same name once" do
      skip('Failing')
      t = @compiler.compile_source(%{ attribute :id ; attribute :id })
      assert_equal([{ :id => :id }], extract_attributes(t.nodes))
    end

    it "aliases attributes through :as option" do
      t = @compiler.compile_source(%{ attribute :foo, :as => :bar })
      assert_equal([{ :bar => :foo }], extract_attributes(t.nodes))
    end

    it "aliases attributes through a hash" do
      t = @compiler.compile_source(%{ attribute :foo => :bar })
      assert_equal([{ :bar => :foo }], extract_attributes(t.nodes))
    end

    it "aliases multiple attributes" do
      t = @compiler.compile_source(%{ attributes :foo => :bar, :id => :uid })
      assert_equal([{ :bar => :foo, :uid => :id }], extract_attributes(t.nodes))
    end

    it "compiles attribtues with a condition" do
      t = @compiler.compile_source(%( attributes :id, if: ->(o) { false } ))
      assert_equal([{ id: :id }], extract_attributes(t.nodes))
      refute_nil t.nodes.first.condition
    end

    it "compiles child with record association" do
      t = @compiler.compile_source(%{ child :address do attributes :foo end})

      assert_equal(1, t.nodes.size)
      child_node = t.nodes.first

      assert_equal(:address, child_node.name)
      assert_equal(:address, child_node.data)
      assert_equal([{ foo: :foo }], extract_attributes(child_node.nodes))
    end

    it "compiles child with association aliased" do
      t = @compiler.compile_source(%{ child :address => :bar do attributes :foo end})
      child_node = t.nodes.first

      assert_equal(:bar, child_node.name)
      assert_equal(:address, child_node.data)
    end

    it "compiles child with root name defined as option" do
      t = @compiler.compile_source(%{ child(:user, :root => :author) do attributes :foo end })
      child_node = t.nodes.first

      assert_equal(:author, child_node.name)
      assert_equal(:user, child_node.data)
    end

    it "compiles child with root name defined with `as` option" do
      t = @compiler.compile_source(%{ child(:user, as: :author) do attributes :foo end })
      child_node = t.nodes.first

      assert_equal(:author, child_node.name)
      assert_equal(:user, child_node.data)
    end

    it "compiles child with arbitrary source" do
      t = @compiler.compile_source(%{ child :@user => :author do attribute :name end })
      child_node = t.nodes.first

      assert_equal(:author, child_node.name)
      assert_equal(:@user, child_node.data)
    end

    it "compiles child with inline partial notation" do
      t = @compiler.compile_source(%{child(:user, :partial => 'user') })
      child_node = t.nodes.first

      assert_equal(:user, child_node.name)
      assert_equal(:user, child_node.data)
      assert_equal([{ id: :id }], extract_attributes(child_node.nodes))
    end

    it "compiles glue as a child but without a name" do
      t = @compiler.compile_source(%{ glue(:@user) do attribute :name end })

      assert_equal(1, t.nodes.size)
      glue_node = t.nodes.first

      assert_equal(:@user, glue_node.data)
      assert_equal([{ name: :name }], extract_attributes(glue_node.nodes))
    end

    it "allows multiple glue within same template" do
      t = @compiler.compile_source(%{
        glue :@user do attribute :name end
        glue :@user do attribute :foo end
      })

      assert_equal(2, t.nodes.size)
    end

    it "compiles glue with RablRails DSL in its body" do
      t = @compiler.compile_source(%{
        glue :@user do node(:foo) { |u| u.name } end
      })

      glue_node = t.nodes.first
      assert_equal(1, glue_node.nodes.size)

      code_node = glue_node.nodes.first
      assert_instance_of(RablRails::Nodes::Code, code_node)
      assert_equal(:foo, code_node.name)
    end

    it "compiles glue with a partial" do
      t = @compiler.compile_source(%{
        glue(:@user, partial: 'user')
      })

      glue_node = t.nodes.first
      assert_equal(1, glue_node.nodes.size)
      assert_equal([{ :id => :id }], extract_attributes(glue_node.nodes))
    end

    it "compiles fetch with record association" do
      t = @compiler.compile_source(%{ fetch :address do attributes :foo end})

      assert_equal(1, t.nodes.size)
      fetch_node = t.nodes.first

      assert_equal(:address, fetch_node.name)
      assert_equal(:address, fetch_node.data)
      assert_equal(:id, fetch_node.field)
      assert_equal([{ foo: :foo }], extract_attributes(fetch_node.nodes))
    end

    it "compiles fetch with options" do
      t = @compiler.compile_source(%{
        fetch(:user, as: :author, field: :uid) do attributes :foo end
      })

      fetch_node = t.nodes.first
      assert_equal(:author, fetch_node.name)
      assert_equal(:user, fetch_node.data)
      assert_equal(:uid, fetch_node.field)
    end

    it "compiles constant node" do
      t = @compiler.compile_source(%{
        const(:locale, 'fr_FR')
      })

      const_node = t.nodes.first
      assert_equal :locale, const_node.name
      assert_equal 'fr_FR', const_node.value
    end

    it "compiles lookup node" do
      t = @compiler.compile_source(%{
        lookup(:favorite, :@user_favorites, cast: true)
      })

      lookup_node = t.nodes.first
      assert_equal :favorite, lookup_node.name
      assert_equal :@user_favorites, lookup_node.data
      assert_equal :id, lookup_node.field
      assert lookup_node.cast_to_boolean?
    end

    it "extends other template" do
      t = @compiler.compile_source(%{ extends 'user' })
      assert_equal([{ :id => :id }], extract_attributes(t.nodes))
    end

    it "extends with a lambda" do
      t = @compiler.compile_source(%{ extends -> { 'user' } })
      node = t.nodes.first
      assert_instance_of(RablRails::Nodes::Polymorphic, node)
      assert_equal('user', node.template_lambda.call)
    end

    it "compiles extend without overwriting nodes previously defined" do
      File.open(@@tmp_path + 'xtnd.rabl', 'w') do |f|
        f.puts %q{
          condition(-> { true }) { 'foo' }
        }
      end
      t = @compiler.compile_source(%{
        condition(-> { false }) { 'bar' }
        extends 'xtnd'
      })
      assert_equal(2, t.nodes.size)
    end

    it "extends template that has been compiled previously by ActionView" do
      t = @view.lookup_context.find_template('user')
      t.send(:compile!, @view)
      t = @compiler.compile_source(%{ extends 'user' })
      assert_equal([{ :id => :id }], extract_attributes(t.nodes))
    end

    it "compiles extends with locals" do
      t    = @compiler.compile_source(%{ extends 'user', locals: { display_credit_card: false } })
      node = t.nodes.first

      assert_instance_of RablRails::Nodes::Extend, node
      assert_equal([{ :id => :id }], extract_attributes(node.nodes))
      assert_equal({ display_credit_card: false }, node.locals)
    end

    it "compiles node" do
      t = @compiler.compile_source(%{ node(:foo) { bar } })

      assert_equal(1, t.nodes.size)
      code_node = t.nodes.first

      assert_equal(:foo, code_node.name)
      assert_instance_of Proc, code_node.block
    end

    it "compiles node with condition option" do
      t = @compiler.compile_source(%{ node(:foo, :if => lambda { |m| m.foo.present? }) do |m| m.foo end })
      code_node = t.nodes.first
      assert_instance_of Proc, code_node.condition
    end

    it "compiles node with no argument" do
      t = @compiler.compile_source(%{ node do |m| m.foo end })
      node = t.nodes.first
      assert_nil node.name
    end

    it "compiles merge like a node" do
      t = @compiler.compile_source(%{ merge do |m| m.foo end })
      node = t.nodes.first
      assert_instance_of RablRails::Nodes::Code, node
      assert_nil node.name
    end

    it "compiles merge with options" do
      t = @compiler.compile_source(%{ merge(->(m) { true }) do |m| m.foo end })
      node = t.nodes.first
      refute_nil node.condition
    end

    it "compiles condition" do
      t = @compiler.compile_source(%{ condition(->(u) {}) do attributes :secret end })

      assert_equal(1, t.nodes.size)
      node = t.nodes.first

      assert_instance_of RablRails::Nodes::Condition, node
      assert_equal([{ secret: :secret }], extract_attributes(node.nodes))
    end

    it "compiles with no object" do
      t = @compiler.compile_source(%{
       object false
       child(:@user => :user) do
         attribute :id
       end
      })

      assert_equal false, t.data
    end

    describe '#extract_data_and_name' do
      it "extracts name from argument" do
        assert_equal [:@users, 'users'], @compiler.send(:extract_data_and_name, :@users)
        assert_equal [:users, :users], @compiler.send(:extract_data_and_name, :users)
        assert_equal [:@users, :authors], @compiler.send(:extract_data_and_name, :@users => :authors)
      end
    end
  end
end
