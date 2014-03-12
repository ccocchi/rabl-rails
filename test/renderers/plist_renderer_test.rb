require 'test_helper'

class TestPlistRenderer < ActiveSupport::TestCase
  INDENT_REGEXP = /\n(\s)*/
  HEADER_REGEXP = /<\?[^>]+><![^>]+>/

  setup do
    @data = User.new(1, 'foobar', 'male')

    @context = Context.new
    @context.assigns['data'] = @data

    @template = RablRails::CompiledTemplate.new
    @template.data = :@data
    @template.root_name = :user
  end

  def render_plist_output
    output = RablRails::Renderers::PLIST.render(@template, @context).to_s.gsub!(INDENT_REGEXP, '')
    output.sub!(HEADER_REGEXP, '').gsub!(%r(</?plist[^>]*>), '').sub!(%r(<dict/?>), '').sub(%r(</dict>), '')
  end

  test "plist engine should responsd to #dump" do
    assert_raises(RuntimeError) { RablRails.plist_engine = Object.new }
  end

  test "render object wth empty template" do
    @template.source = {}
    assert_equal %q(), render_plist_output
  end

  test "render collection with empty template" do
    @context.assigns['data'] = [@data]
    @template.source = {}
    assert_equal %q(<array></array>), render_plist_output
  end

  test "render object with local methods (used by decent_exposure)" do
    @context.stub(:user).and_return(@data)
    @template.data = :user
    @template.source = { :id => :id }
    assert_equal %q(<key>id</key><integer>1</integer>), render_plist_output
  end

  test "render single object attributes" do
    @template.source = { :id => :id, :name => :name }
    assert_equal %q(<key>id</key><integer>1</integer><key>name</key><string>foobar</string>), render_plist_output
  end

  test "render child with object association" do
    @data.stub(:address).and_return(double(:city => 'Paris'))
    @template.source = { :address => { :_data => :address, :city => :city } }
    assert_equal %q(<key>address</key><dict><key>city</key><string>Paris</string></dict>), render_plist_output
  end

  test "render child with arbitrary data source" do
    @template.source = { :author => { :_data => :@data, :name => :name } }
    assert_equal %q(<key>author</key><dict><key>name</key><string>foobar</string></dict>), render_plist_output
  end

  test "render child with local methods (used by decent_exposure)" do
    @context.stub(:user).and_return(@data)
    @template.source = { :author => { :_data => :user, :name => :name } }
    assert_equal %q(<key>author</key><dict><key>name</key><string>foobar</string></dict>), render_plist_output
  end

  test "render node property" do
    proc = lambda { |object| object.name }
    @template.source = { :name => proc }
    assert_equal %q(<key>name</key><string>foobar</string>), render_plist_output
  end

  test "render node property with true condition" do
    condition = lambda { |u| true }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal %q(<key>name</key><string>foobar</string>), render_plist_output
  end

  test "render node property with false condition" do
    condition = lambda { |u| false }
    proc = lambda { |object| object.name }
    @template.source = { :name => [condition, proc] }
    assert_equal %q(), render_plist_output
  end

  test "node with context method call" do
    @context.stub(:respond_to?).with(:@data).and_return(false)
    @context.stub(:respond_to?).with(:context_method).and_return(true)
    @context.stub(:context_method).and_return('marty')
    proc = lambda { |object| context_method }
    @template.source = { :name => proc }
    assert_equal %q(<key>name</key><string>marty</string>), render_plist_output
  end

  test "partial with no values should raise an error" do
    @template.data = false
    @template.source = { :user => ->(s) { partial('users/base') } }

    assert_raises(RablRails::Renderers::PartialError) { render_plist_output }
  end

  test "partial with empty values should not raise an error" do
    @template.data = false
    @template.source = { :users => ->(s) { partial('users/base', :object => []) } }

    assert_equal %q(<key>users</key><array/>), render_plist_output
  end

  test "condition blocks are transparent if the condition passed" do
    c = RablRails::Condition.new(->(u) { true }, { :name => :name })
    @template.source = { :_if0 => c }
    assert_equal %q(<key>name</key><string>foobar</string>), render_plist_output
  end

  test "condition blocks are ignored if the condition is not met" do
    c = RablRails::Condition.new(->(u) { false }, { :name => :name })
    @template.source = { :_if0 => c }
    assert_equal %q(), render_plist_output
  end

  test "render object with root node" do
    RablRails.include_plist_root = true
    @template.root_name = :author
    @template.source = { :id => :id, :name => :name }
    assert_equal %q(<key>author</key><dict><key>id</key><integer>1</integer><key>name</key><string>foobar</string></dict>), render_plist_output
  end

  test "render object with root options set to false" do
    RablRails.include_plist_root = false
    @template.root_name = :author
    @template.source = { :id => :id, :name => :name }
    assert_equal %q(<key>id</key><integer>1</integer><key>name</key><string>foobar</string>), render_plist_output
  end
end