require 'test_helper'

class TestHashRenderer < MiniTest::Unit::TestCase
  describe 'hash renderer' do
    def render(locals = nil)
      Visitors::ToHash.stub :new, @visitor do
        RablRails::Renderers::Hash.render(@template, @context, locals)
      end
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
      @visitor  = Visitors::ToHash.new(@context)
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
  end


  # setup do
  #   @data = User.new(1, 'foobar', 'male')

  #   @context = Context.new
  #   @context.assigns['data'] = @data

  #   @template = RablRails::CompiledTemplate.new
  #   @template.data = :@data

  #   @cache = double
  #   Rails.stub(:cache).and_return(@cache)
  # end

  # def render_hash
  #   RablRails::Renderers::Hash.render(@template, @context)
  # end

  # test "cache should be applied if no cache key is given" do
  #   @cache.should_not_receive(:fetch)
  #   render_hash
  # end

  # test "cache should not be used if disabled in Rails configuration" do
  #   ActionController::Base.stub(:perform_caching).and_return(false)
  #   @cache.should_not_receive(:fetch)
  #   @template.cache_key = 'something'
  #   render_hash
  # end

  # test "cache shoud use #cache_key as default" do
  #   ActionController::Base.stub(:perform_caching).and_return(true)
  #   @data.stub(:cache_key).and_return('data_cache_key')
  #   @cache.should_receive(:fetch).with('data_cache_key').and_return({ some: 'hash' })
  #   @template.cache_key = nil

  #   assert_equal({ some: 'hash' }, render_hash)
  # end

  # test "cache should use the proc if given" do
  #   ActionController::Base.stub(:perform_caching).and_return(true)
  #   @template.cache_key = ->(u) { 'proc_cache_key' }
  #   @cache.should_receive(:fetch).with('proc_cache_key').and_return({ some: 'hash' })

  #   assert_equal({ some: 'hash' }, render_hash)
  # end
end