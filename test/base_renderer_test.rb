require 'test_helper'

class TestBaseRenderer < ActiveSupport::TestCase

  RablRails::Renderers::Base.class_eval do
    def format_output(hash)
      hash
    end
  end

  setup do
    @data = User.new(1, 'foobar', 'male')

    @context = Context.new
    @context.assigns['data'] = @data

    @template = RablRails::CompiledTemplate.new
    @template.source = {}
    @template.data = :@data

    @cache = mock
    Rails.stub(:cache).and_return(@cache)
  end

  def render_hash
    RablRails::Renderers::Base.new(@context).render(@template)
  end

  test "child with nil data should render nil" do
    @template.source = { :author => { :_data => :@nil, :name => :name } }
    assert_equal({ :author => nil }, render_hash)
  end

  test "properly handle assigns with symbol keys" do
    @context.assigns[:foo] = 'bar'
    assert_nothing_raised { render_hash }
  end

  test "cache should be applied if no cache key is given" do
    @cache.should_not_receive(:fetch)
    render_hash
  end

  test "cache should not be used if disabled in Rails configuration" do
    ActionController::Base.stub(:perform_caching).and_return(false)
    @cache.should_not_receive(:fetch)
    @template.cache_key = 'something'
    render_hash
  end

  test "cache shoud use #cache_key as default" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    @data.stub(:cache_key).and_return('data_cache_key')
    @cache.should_receive(:fetch).with('data_cache_key').and_return({ some: 'hash' })
    @template.cache_key = nil

    assert_equal({ some: 'hash' }, render_hash)
  end

  test "cache should use the proc if given" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    @template.cache_key = ->(u) { 'proc_cache_key' }
    @cache.should_receive(:fetch).with('proc_cache_key').and_return({ some: 'hash' })

    assert_equal({ some: 'hash' }, render_hash)
  end
end