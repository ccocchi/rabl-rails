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
    output = RablRails::Renderers::PLIST.new(@context).render(@template).to_s.gsub!(INDENT_REGEXP, '')
    output.sub!(HEADER_REGEXP, '').gsub!(%r(</?plist[^>]*>), '').sub!(%r(<dict/?>), '').sub(%r(</dict>), '')
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
    @data.stub(:address).and_return(mock(:city => 'Paris'))
    @template.source = { :address => { :_data => :address, :city => :city } }


    assert_equal %q(<key>address</key><dict><key>city</key><string>Paris</string></dict>), render_plist_output
  end
end