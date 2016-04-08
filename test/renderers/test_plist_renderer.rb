require 'helper'

class TestPListRenderer < Minitest::Test
  INDENT_REGEXP = /\n(\s)*/
  HEADER_REGEXP = /<\?[^>]+><![^>]+>/

   describe 'PList renderer' do
    def render
      output = RablRails::Renderers::PLIST.render(@template, @context).to_s.gsub!(INDENT_REGEXP, '')
      output.sub!(HEADER_REGEXP, '').gsub!(%r(</?plist[^>]*>), '').sub!(%r(<dict/?>), '').sub(%r(</dict>), '')
    end

    before do
      @resource = User.new(1, 'Marty')
      @context  = Context.new
      @context.assigns['user'] = @resource
      @template = RablRails::CompiledTemplate.new
      @template.data = :@user
      @template.add_node RablRails::Nodes::Attribute.new(name: :name)
    end

    it 'extends hash renderer' do
      RablRails::Renderers::PLIST.ancestors.include?(RablRails::Renderers::Hash)
    end

    it 'renders PList' do
      assert_equal %q(<key>name</key><string>Marty</string>), render
    end

    it 'uses template root_name option if include_plist_root is set' do
      @template.root_name = :user
      with_configuration :include_plist_root, true do
        assert_equal %q(<key>user</key><dict><key>name</key><string>Marty</string></dict>), render
      end
    end

    it 'ignores template root_name by default' do
      @template.root_name = :user
      assert_equal %q(<key>name</key><string>Marty</string>), render
    end
  end
end