require 'test_helper'

class TestHashVisitor < MiniTest::Unit::TestCase
  describe 'ToHash visitor' do
    def visitor_result
      visitor = Visitors::ToHash.new(@context)
      visitor.reset_for @resource
      visitor.visit @nodes
      visitor._result
    end

    before do
      @context  = Context.new
      @resource = User.new(1, 'Marty')
      @nodes    = []
    end

    it 'renders empty nodes list' do
      assert_equal({}, visitor_result)
    end

    it 'renders attributes node' do
      @nodes << RablRails::Nodes::Attribute.new(id: :id)
      assert_equal({ id: 1 }, visitor_result)
    end

    it 'renders array of nodes' do
      @nodes = [
        RablRails::Nodes::Attribute.new(id: :id),
        RablRails::Nodes::Attribute.new(name: :name)
      ]
      assert_equal({ id: 1, name: 'Marty' }, visitor_result)
    end

    describe 'with a child node' do
      Address = Struct.new(:city)

      before do
        @template = RablRails::CompiledTemplate.new
        @template.add_node(RablRails::Nodes::Attribute.new(city: :city))
        @nodes << RablRails::Nodes::Child.new(:address, @template)
        @address = Address.new('Paris')
      end

      it 'renders with resource association as data source' do
        @template.data = :address
        def @resource.address; end
        @resource.stub :address, @address do
          assert_equal({ address: { city: 'Paris' } }, visitor_result)
        end
      end

      it 'renders with arbitrary data source' do
        @template.data = :@address
        @context.assigns['address'] = @address
        assert_equal({ address: { city: 'Paris' } }, visitor_result)
      end

      it 'renders with local method as data source' do
        @template.data = :address
        def @context.address; end
        @context.stub :address, @address do
          assert_equal({ address: { city: 'Paris' } }, visitor_result)
        end
      end

      it 'renders with a collection as data source' do
        @template.data = :address
        def @context.address; end
        @context.stub :address, [@address, @address] do
          assert_equal({ address: [
            { city: 'Paris' },
            { city: 'Paris' }
          ]}, visitor_result)
        end
      end

      it 'renders if the source is nil' do
        @template.data = :address
        def @resource.address; end
        @resource.stub :address, nil do
          assert_equal({ address: nil }, visitor_result)
        end
      end
    end

    it 'renders glue nodes' do
      template = RablRails::CompiledTemplate.new
      template.add_node(RablRails::Nodes::Attribute.new(name: :name))
      template.data = :@user

      @nodes << RablRails::Nodes::Glue.new(template)
      @context.assigns['user'] = @resource
      assert_equal({ name: 'Marty'}, visitor_result)
    end

    describe 'with a code node' do
      before do
        @proc = ->(object) { object.name }
      end

      it 'renders the evaluated proc' do
        @nodes << RablRails::Nodes::Code.new(:name, @proc)
        assert_equal({ name: 'Marty'}, visitor_result)
      end

      it 'renders with a true condition' do
        @nodes << RablRails::Nodes::Code.new(:name, @proc, ->(o) { true })
        assert_equal({ name: 'Marty'}, visitor_result)
      end

      it 'renders nothing with a false condition' do
        @nodes << RablRails::Nodes::Code.new(:name, @proc, ->(o) { false })
        assert_equal({}, visitor_result)
      end

      it 'renders method called from context' do
        @proc = ->(object) { context_method }
        def @context.context_method; end

        @nodes = [RablRails::Nodes::Code.new(:name, @proc)]
        @context.stub :context_method, 'Biff' do
          assert_equal({ name: 'Biff'}, visitor_result)
        end
      end
    end

    describe 'with a condition node' do
      before do
        @ns = [RablRails::Nodes::Attribute.new(name: :name)]
      end

      it 'renders transparently if the condition is met' do
        @nodes << RablRails::Nodes::Condition.new(->(o) { true }, @ns)
        assert_equal({ name: 'Marty' }, visitor_result)
      end

      it 'renders nothing if the condition is not met' do
        @nodes << RablRails::Nodes::Condition.new(->(o) { false }, @ns)
        assert_equal({}, visitor_result)
      end
    end

    it 'renders a merge node' do
      proc = ->(c) { { custom: c.name } }
      @nodes << RablRails::Nodes::Code.new(nil, proc)
      assert_equal({ custom: 'Marty' }, visitor_result)
    end

    it 'raises an exception when trying to merge a non hash object' do
      proc = ->(c) { c.name }
      @nodes << RablRails::Nodes::Code.new(nil, proc)
      assert_raises(RablRails::Renderer::PartialError) { visitor_result }
    end

    it 'renders partial defined in code node' do
      template = RablRails::CompiledTemplate.new
      template.add_node(RablRails::Nodes::Attribute.new(name: :name))
      proc = ->(u) { partial('users/base', object: u) }

      @nodes << RablRails::Nodes::Code.new(:user, proc)
      RablRails::Library.instance.stub :compile_template_from_path, template do
        assert_equal({ user: { name: 'Marty' } }, visitor_result)
      end
    end

    it 'renders partial with empty target' do
      proc = ->(u) { partial('users/base', object: []) }
      @nodes << RablRails::Nodes::Code.new(:users, proc)
      assert_equal({ users: [] }, visitor_result)
    end

    it 'raises an exception when calling a partial without a target' do
      proc = ->(u) { partial('users/base') }
      @nodes << RablRails::Nodes::Code.new(:user, proc)
      assert_raises(RablRails::Renderer::PartialError) { visitor_result }
    end
  end
end