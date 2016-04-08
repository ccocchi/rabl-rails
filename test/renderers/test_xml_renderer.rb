require 'helper'

class TestXMLRenderer < Minitest::Test
  INDENT_REGEXP = /\n(\s)*/
  HEADER_REGEXP = /<[^>]+>/

  describe 'XML renderer' do
    def render
      RablRails::Renderers::XML.render(@template, @context).to_s.gsub!(INDENT_REGEXP, '').sub!(HEADER_REGEXP, '')
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
      RablRails::Renderers::XML.ancestors.include?(RablRails::Renderers::Hash)
    end

    it 'uses global XML options' do
      @template.nodes = [RablRails::Nodes::Attribute.new(first_name: :name)]
      with_configuration :xml_options, { dasherize: false, skip_types: false } do
        assert_equal %q(<hash><first_name>Marty</first_name></hash>), render
      end
    end

    it 'uses template root_name option' do
      @template.root_name = :user
      assert_equal %q(<user><name>Marty</name></user>), render
    end
  end
end