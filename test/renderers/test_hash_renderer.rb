require 'helper'

class TestHashRenderer < Minitest::Test
  describe 'hash renderer' do
    def render
      RablRails::Renderers::Hash.render(@template, @context, {})
    end

    def with_cache
      ActionController::Base.stub :perform_caching, true do
        Rails.stub :cache, @cache do
          yield
        end
      end
    end

    before do
      @cache    = MiniTest::Mock.new
      @resource = User.new(1, 'Marty')
      @context  = Context.new
      @context.assigns['user'] = @resource
      @template = RablRails::CompiledTemplate.new
      @template.data = :@user
      @template.add_node RablRails::Nodes::Attribute.new(name: :name)
    end

    describe 'cache' do
      it 'uses resource cache_key by default' do
        def @resource.cache_key; 'marty_cache' end
        @template.cache_key = nil
        @cache.expect :fetch, { user: 'Marty' }, ['marty_cache']
        with_cache {
          assert_equal({ user: 'Marty' }, render)
        }
        @cache.verify
      end

      it 'uses template cache_key if present' do
        @template.cache_key = ->(u) { u.name }
        @cache.expect :fetch, { user: 'Marty' }, ['Marty']
        with_cache {
          assert_equal({ user: 'Marty' }, render)
        }
        @cache.verify
      end
    end

    it 'uses a to_hash visitor' do
      visitor = MiniTest::Mock.new
      visitor.expect :instance_variable_get, @resource, [:@user]
      visitor.expect :reset_for, nil, [@resource]
      visitor.expect :visit, nil, [Array]
      visitor.expect :result, { some: 'result' }

      Visitors::ToHash.stub :new, visitor do
        assert_equal({ some: 'result' }, render)
      end

      visitor.verify
    end

    it 'retrieves data from context if exist' do
      @template.data = :context_method
      resource = User.new(2, 'Biff')
      @context.stub :context_method, resource do
        assert_equal({ name: 'Biff' }, render)
      end
    end

    it 'uses assigns from context if context has no data method' do
      assert_equal({ name: 'Marty' }, render)
    end

    it 'uses template root_name option' do
      @template.root_name = :user
      assert_equal({ user: { name: 'Marty' } }, render)
    end

    it 'renders collection' do
      @context.assigns['user'] = [@resource]
      assert_equal([{ name: 'Marty' }], render)
    end
  end
end
