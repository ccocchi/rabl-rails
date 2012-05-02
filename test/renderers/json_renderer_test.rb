require 'test_helper'

class TestJsonRenderer < ActiveSupport::TestCase

  setup do
    @data = User.new(1, 'foobar', 'male')
    @data.stub(:respond_to?).with(:each).and_return(false)

    @context = Context.new
    @context.stub(:instance_variable_get).with(:@data).and_return(@data)
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({})

    @template = RablRails::CompiledTemplate.new
    @template.data = :@data
  end

  def render_json_output
    RablRails::Renderers::JSON.new(@context).render(@template).to_s
  end

  test "render object wth empty template" do
    @template.source = {}
    assert_equal %q({}), render_json_output
  end

  test "render collection with empty template" do
    @context.stub(:instance_variable_get).with(:@data).and_return([@data])
    @template.source = {}
    assert_equal %q([{}]), render_json_output
  end

  test "render single object attributes" do
    @template.source = { :id => :id, :name => :name }
    assert_equal %q({"id":1,"name":"foobar"}), render_json_output
  end

  test "render child with object association" do
    @data.stub(:address).and_return(mock(:city => 'Paris'))
    @template.source = { :address => { :_data => :address, :city => :city } }
    assert_equal %q({"address":{"city":"Paris"}}), render_json_output
  end

  test "render child with arbitrary data source" do
    @template.source = { :author => { :_data => :@data, :name => :name } }
    assert_equal %q({"author":{"name":"foobar"}}), render_json_output
  end

  test "render glued attributes from single object" do
    @template.source = { :_glue0 => { :_data => :@data, :name => :name } }
    assert_equal %q({"name":"foobar"}), render_json_output
  end

  test "render collection with attributes" do
    @data = [User.new(1, 'foo', 'male'), User.new(2, 'bar', 'female')]
    @context.stub(:instance_variable_get).with(:@data).and_return(@data)
    @template.source = { :uid => :id, :name => :name, :gender => :sex }
    assert_equal %q([{"uid":1,"name":"foo","gender":"male"},{"uid":2,"name":"bar","gender":"female"}]), render_json_output
  end

  test "render node property" do
    proc = lambda { |object| object.name }
    @template.source = { :name => proc }
    assert_equal %q({"name":"foobar"}), render_json_output
  end

  test "render node property with true condition" do
    condition = lambda { |u| true }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal %q({"name":"foobar"}), render_json_output
  end

  test "render node property with false condition" do
    condition = lambda { |u| false }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal %q({}), render_json_output
  end
  
  test "node with context method call" do
    @context.stub(:respond_to?).with(:context_method).and_return(true)
    @context.stub(:context_method).and_return('marty')
    proc = lambda { |object| context_method }
    @template.source = { :name => proc }
    assert_equal %q({"name":"marty"}), render_json_output
  end

  test "partial should be evaluated at rendering time" do
    # Set assigns
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({'user' => @data})
    @data.stub(:respond_to?).with(:empty?).and_return(false)

    # Stub Library#get
    t = RablRails::CompiledTemplate.new
    t.source = { :name => :name }
    RablRails::Library.reset_instance
    RablRails::Library.instance.should_receive(:get).with('users/base').and_return(t)

    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base', :object => @user) } }

    assert_equal %q({"user":{"name":"foobar"}}), render_json_output
  end

  test "partial with no values should raise an error" do
    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base') } }

    assert_raises(RablRails::Renderers::PartialError) { render_json_output }
  end

  test "partial with empty values should not raise an error" do
    @template.data = false
    @template.source = { :users => ->(s) { partial('users/base', :object => []) } }

    assert_equal %q({"users":[]}), render_json_output
  end
end