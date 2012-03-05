require 'test_helper'

class TestCompiledTemplate < ActiveSupport::TestCase

  setup do
    @context = Context.new
    @data = User.new(1, 'foobar', 'male')
    @data.stub(:respond_to?).with(:each).and_return(false)
    @context.stub(:instance_variable_get).with(:@data).and_return(@data)
    @template = RablFastJson::CompiledTemplate.new
    @template.context = @context
    @template.data = :@data
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

  test "render object with node property" do
    proc = lambda { |object| object.sex }
    @template.source = { :sex => proc }
    assert_equal({ :sex => 'male' }, @template.render)
  end

  test "render obejct with conditionnal node property" do
    condition = lambda { |u| u.name.present? }
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
end