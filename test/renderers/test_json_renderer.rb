require 'helper'

class TestJSONRenderer < Minitest::Test
  describe 'JSON renderer' do
    def render
      RablRails::Renderers::JSON.render(@template, @context)
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
      RablRails::Renderers::JSON.ancestors.include?(RablRails::Renderers::Hash)
    end

    it 'renders JSON' do
      assert_equal %q({"name":"Marty"}), render
    end

    it 'uses template root_name option' do
      @template.root_name = :user
      assert_equal %q({"user":{"name":"Marty"}}), render
    end

    it 'ignores template root_name option if include_json_root is disabled' do
      @template.root_name = :user
      with_configuration :include_json_root, false do
        assert_equal %q({"name":"Marty"}), render
      end
    end

    it 'renders jsonp callback' do
      @context.stub :params, { callback: 'some_callback' } do
        with_configuration :enable_jsonp_callbacks, true do
          assert_equal %q[some_callback({"name":"Marty"})], render
        end
      end
    end
  end
end