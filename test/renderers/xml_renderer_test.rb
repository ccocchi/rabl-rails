require 'test_helper'

class TestXmlRenderer < ActiveSupport::TestCase
  INDENT_REGEXP = /\n(\s)*/
  HEADER_REGEXP = /<[^>]+>/

  setup do
    @data = User.new(1, 'foobar', 'male')

    @context = Context.new
    @context.assigns['data'] = @data

    @template = RablRails::CompiledTemplate.new
    @template.data = :@data
    @template.root_name = :user
  end

  def render_xml_output
    RablRails::Renderers::XML.new(@context).render(@template).to_s.gsub!(INDENT_REGEXP, '').sub!(HEADER_REGEXP, '')
  end

  test "render object simple object" do
    @template.source = {}
    assert_equal %q(<user></user>), render_xml_output
  end

  test "render collection with empty template" do
    @context.assigns['data'] = [@data]
    @template.source = {}
    @template.root_name = :users
    assert_equal %q(<users type="array"><user></user></users>), render_xml_output
  end

  test "render object with local methods (used by decent_exposure)" do
    @context.stub(:user).and_return(@data)
    @template.source = { :id => :id }
    assert_equal %q(<user><id type="integer">1</id></user>), render_xml_output
  end

  test "render single object attributes" do
    @template.source = { :name => :name }
    assert_equal %q(<user><name>foobar</name></user>), render_xml_output
  end

  test "render child with arbitrary data source" do
    @template.source = { :author => { :_data => :@data, :name => :name } }
    @template.root_name = :post
    assert_equal %q(<post><author><name>foobar</name></author></post>), render_xml_output
  end

  test "render child with local methods (used by decent_exposure)" do
    @context.stub(:user).and_return(@data)
    @template.source = { :author => { :_data => :user, :name => :name } }
    @template.root_name = :post
    assert_equal %q(<post><author><name>foobar</name></author></post>), render_xml_output
  end

  test "render glued attributes from single object" do
    @template.source = { :_glue0 => { :_data => :@data, :name => :name } }
    assert_equal %q(<user><name>foobar</name></user>), render_xml_output
  end

  test "render collection with attributes" do
    @data = [User.new(1, 'foo', 'male'), User.new(2, 'bar', 'female')]
    @context.assigns['data'] = @data
    @template.root_name = :users
    @template.source = { :uid => :id, :name => :name }
    assert_equal %q(<users type="array"><user><uid type="integer">1</uid><name>foo</name></user><user><uid type="integer">2</uid><name>bar</name></user></users>), render_xml_output
  end

  test "render node property" do
    proc = lambda { |object| object.name }
    @template.source = { :name => proc }
    assert_equal %q(<user><name>foobar</name></user>), render_xml_output
  end

  test "render node property with true condition" do
    condition = lambda { |u| true }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal %q(<user><name>foobar</name></user>), render_xml_output
  end

  test "render node property with false condition" do
    condition = lambda { |u| false }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal %q(<user></user>), render_xml_output
  end

  test "node with context method call" do
    @context.stub(:respond_to?).with(:@data).and_return(false)
    @context.stub(:respond_to?).with(:context_method).and_return(true)
    @context.stub(:context_method).and_return('marty')
    proc = lambda { |object| context_method }
    @template.source = { :name => proc }
    assert_equal %q(<user><name>marty</name></user>), render_xml_output
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
    @template.root_name = :post
    @template.source = { :user => ->(s) { partial('users/base', :object => @user) } }

    assert_equal %q(<post><user><name>foobar</name></user></post>), render_xml_output
  end

  test "partial with no values should raise an error" do
    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base') } }

    assert_raises(RablRails::Renderers::PartialError) { render_xml_output }
  end

  test "partial with empty values should not raise an error" do
    @template.data = false
    @template.root_name = :list
    @template.source = { :users => ->(s) { partial('users/base', :object => []) } }

    assert_equal %q(<list><users type="array"/></list>), render_xml_output
  end

  test "render underscorized xml" do
    RablRails.xml_options = { :dasherize => false, :skip_types => false }
    @template.source = { :first_name => :name }
    assert_equal %q(<user><first_name>foobar</first_name></user>), render_xml_output
  end
end