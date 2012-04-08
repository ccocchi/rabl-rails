require 'test_helper'

class TestCompiledTemplate < ActiveSupport::TestCase

  setup do
    @context = Context.new
    @data = User.new(1, 'foobar', 'male')
    @data.stub(:respond_to?).with(:each).and_return(false)
    @context.stub(:instance_variable_get).with(:@data).and_return(@data)
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({})
    @template = RablFastJson::CompiledTemplate.new
    @template.context = @context
    @template.data = :@data
  end

  test "render object wth empty template" do
    @template.source = {}
    assert_equal({}, @template.render)
  end

  test "render collection with empty template" do
    @context.stub(:instance_variable_get).with(:@data).and_return([@data])
    @template.source = {}
    assert_equal([{}], @template.render)
  end

  test "render single object attributes" do
    @template.source = { :id => :id, :name => :name }
    assert_equal({ :id => 1, :name => 'foobar'}, @template.render)
  end

  test "render object as a child" do
    @template.source = { :author => { :_data => :@data, :name => :name } }
    assert_equal({ :author => { :name => 'foobar' } }, @template.render)
  end

  test "render glued attributes from single object" do
    @template.source = { :_glue0 => { :_data => :@data, :name => :name } }
    assert_equal({ :name => 'foobar' }, @template.render)
  end

  test "render collection with attributes" do
    @data = [User.new(1, 'foo', 'male'), User.new(2, 'bar', 'female')]
    @context.stub(:instance_variable_get).with(:@data).and_return(@data)
    @template.source = { :uid => :id, :name => :name, :gender => :sex }
    assert_equal([
      { :uid => 1, :name => 'foo', :gender => 'male'},
      { :uid => 2, :name => 'bar', :gender => 'female'}
    ], @template.render)
  end

  test "render node property" do
    proc = lambda { |object| object.sex }
    @template.source = { :sex => proc }
    assert_equal({ :sex => 'male' }, @template.render)
  end

  test "render node property with true condition" do
    condition = lambda { |u| true }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal({ :name => 'foobar' }, @template.render)
  end

  test "render node property with false condition" do
    condition = lambda { |u| false }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal({}, @template.render)
  end

  test "partial should be evaluated at rendering time" do
    # Set assigns
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({'user' => @data})
    @data.stub(:respond_to?).with(:empty?).and_return(false)

    # Stub Library#get
    t = RablFastJson::CompiledTemplate.new
    t.source, t.context = { :name => :name }, @context
    RablFastJson::Library.reset_instance
    RablFastJson::Library.instance.should_receive(:get).with('users/base').and_return(t)

    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base', :object => @user) } }

    assert_equal({ :user => { :name => 'foobar' } }, @template.render)
  end

  test "partial with nil values should raise an error" do
    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base') } }

    assert_raises(RuntimeError) { @template.render }
  end

  test "partial with empty values should not raise an error" do
    @template.data = false
    @template.source = { :users => ->(s) { partial('users/base', :object => []) } }

    assert_equal({ :users => [] }, @template.render)
  end
end