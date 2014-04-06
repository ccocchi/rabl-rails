require 'helper'

class TestLibrary < MiniTest::Unit::TestCase
  RablRails::Library.send(:attr_reader, :cached_templates)

  describe 'library' do
    before do
      @library = RablRails::Library.instance
      @library.reset_cache!
      @context = Context.new
      @template = RablRails::CompiledTemplate.new
    end

    describe '#get_rendered_template' do
      it 'compiles and renders template' do
        renderer = MiniTest::Mock.new
        renderer.expect :render, '{}', [@template, @context, nil]

        result = @library.stub :compile_template_from_source, @template do
          RablRails::Renderers.stub :const_get, renderer do
            @library.get_rendered_template '', @context
          end
        end

        assert_equal '{}', result
        assert renderer.verify
      end

      it 'accepts format as string' do
        result = @library.stub :compile_template_from_source, @template do
          @context.stub :params, { format: 'xml' } do
            RablRails::Renderers::XML.stub :render, '<xml>' do
              @library.get_rendered_template '', @context
            end
          end
        end

        assert_equal '<xml>', result
      end

      it 'accepts format as symbol' do
        result = @library.stub :compile_template_from_source, @template do
          @context.stub :params, { format: :plist } do
            RablRails::Renderers::PLIST.stub :render, '<plist>' do
              @library.get_rendered_template '', @context
            end
          end
        end

        assert_equal '<plist>', result
      end
    end

    describe '#compile_template_from_source' do
      it 'compiles a template' do
        compiler = MiniTest::Mock.new
        compiler.expect :compile_source, @template, ['attribute :id']

        result = RablRails::Compiler.stub :new, compiler do
          @library.compile_template_from_source('attribute :id', @context)
        end

        assert_equal @template, result
      end

      it 'caches compiled template if option is set' do
        @context.virtual_path = 'users/base'
        template = with_configuration :cache_templates, true do
          @library.compile_template_from_source("attribute :id", @context)
        end

        assert_equal(template, @library.cached_templates['users/base'])
      end

      it 'compiles source without caching it if options is not set' do
        @context.virtual_path = 'users/base'
        template = with_configuration :cache_templates, false do
          @library.compile_template_from_source("attribute :id", @context)
        end

        assert_empty @library.cached_templates
      end
    end
  end
end