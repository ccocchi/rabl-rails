require 'test_helper'

class TestRubyRenderer < ActiveSupport::TestCase

  setup do
    @data = User.new(1, 'foobar', 'male')

    @context = Context.new
    @context.assigns['data'] = @data

    @template = RablRails::CompiledTemplate.new
    @template.data = :@data
  end

  def render_ruby_output
    RablRails::Renderers::RUBY.new(@context).render(@template)
  end

  test "render object wth empty template" do
    @template.source = {}
    assert_equal({}, render_ruby_output)
  end

  test "render collection with empty template" do
    @context.assigns['data'] = [@data]
    @template.source = {}
    assert_equal [{}], render_ruby_output
  end

  test "render object with local methods (used by decent_exposure)" do
    @context.stub(:user).and_return(@data)
    @template.data = :user
    @template.source = { :id => :id }
    assert_equal({:id  => 1}, render_ruby_output)
  end

  test "render single object attributes" do
    @template.source = { :id => :id, :name => :name }
    assert_equal({:id => 1, :name => 'foobar'}, render_ruby_output)
  end

  test "render child with object association" do
    @data.stub(:address).and_return(mock(:city => 'Paris'))
    @template.source = { :address => { :_data => :address, :city => :city } }
    assert_equal({:address => {:city => "Paris" }}, render_ruby_output)
  end

  test "render child with arbitrary data source" do
    @template.source = { :author => { :_data => :@data, :name => :name } }
    assert_equal({:author => {:name => "foobar"}}, render_ruby_output)
  end

  test "render child with local methods (used by decent_exposure)" do
    @context.stub(:user).and_return(@data)
    @template.source = { :author => { :_data => :user, :name => :name } }
    assert_equal({:author => {:name => "foobar"}}, render_ruby_output)
  end

  test "render glued attributes from single object" do
    @template.source = { :_glue0 => { :_data => :@data, :name => :name } }
    assert_equal({:name => "foobar"}, render_ruby_output)
  end

  test "render glued node" do
    @template.source = { :_glue0 => { :_data => :@data, :foo => lambda { |u| u.name } } }
    assert_equal({:foo => "foobar"}, render_ruby_output)
  end

  test "render collection with attributes" do
    @data = [User.new(1, 'foo', 'male'), User.new(2, 'bar', 'female')]
    @context.assigns['data'] = @data
    @template.source = { :uid => :id, :name => :name, :gender => :sex }
    assert_equal([{:uid => 1,:name=>"foo",:gender=>"male"}, {:uid=>2,:name=>"bar",:gender=>"female"}], render_ruby_output)
  end

  test "render node property" do
    proc = lambda { |object| object.name }
    @template.source = { :name => proc }
    assert_equal({:name => "foobar"}, render_ruby_output)
  end

  test "render node property with true condition" do
    condition = lambda { |u| true }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal({:name=>"foobar"}, render_ruby_output)
  end

  test "render node property with false condition" do
    condition = lambda { |u| false }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal( {}, render_ruby_output)
  end

  test "node with context method call" do
    @context.stub(:respond_to?).with(:@data).and_return(false)
    @context.stub(:respond_to?).with(:context_method).and_return(true)
    @context.stub(:context_method).and_return('marty')
    proc = lambda { |object| context_method }
    @template.source = { :name => proc }
    assert_equal({:name => "marty"}, render_ruby_output)
  end

  test "partial should be evaluated at rendering time" do
    # Set assigns
    @context.assigns['user'] = @data

    # Stub Library#get
    t = RablRails::CompiledTemplate.new
    t.source = { :name => :name }
    RablRails::Library.reset_instance
    RablRails::Library.instance.should_receive(:compile_template_from_path).with('users/base').and_return(t)

    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base', :object => @user) } }

    assert_equal({:user => {:name => "foobar"}}, render_ruby_output)
  end

  test "partial with no values should raise an error" do
    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base') } }

    assert_raises(RablRails::Renderers::PartialError) { render_ruby_output }
  end

  test "partial with empty values should not raise an error" do
    @template.data = false
    @template.source = { :users => ->(s) { partial('users/base', :object => []) } }

    assert_equal( {:users=>[]}, render_ruby_output)
  end

  test "condition blocks are transparent if the condition passed" do
    c = RablRails::Condition.new(->(u) { true }, { :name => :name })
    @template.source = { :_if0 => c }
    assert_equal({:name => "foobar"}, render_ruby_output)
  end

  test "condition blocks are ignored if the condition is not met" do
    c = RablRails::Condition.new(->(u) { false }, { :name => :name })
    @template.source = { :_if0 => c }
    assert_equal({}, render_ruby_output)
  end

  test "render object with root node" do
    RablRails.include_json_root = true
    @template.root_name = :author
    @template.source = { :id => :id, :name => :name }
    assert_equal({:author => {:id=>1,:name=>"foobar"}}, render_ruby_output)
  end

  test "render object with root options set to false" do
    RablRails.include_json_root = false
    @template.root_name = :author
    @template.source = { :id => :id, :name => :name }
    assert_equal({:id=>1,:name=>"foobar"}, render_ruby_output)
  end

  test "merge should raise is return from given block is not a hash" do
    @template.source = { :_merge0 => ->(c) { 'foo' } }
    assert_raises(RablRails::Renderers::PartialError) { render_ruby_output }
  end


  test "cache key should be different from Base to avoid name collisions" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    @data.stub(:cache_key).and_return('data_cache_key')
    @template.cache_key = nil

    @cache = mock
    @cache.should_receive(:fetch).with('data_cache_key.ruby').and_return({:some => "ruby"})
    Rails.stub(:cache).and_return(@cache)

    assert_equal({:some=>"ruby"}, render_ruby_output)
  end
end

