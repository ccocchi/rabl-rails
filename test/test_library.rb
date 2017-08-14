require 'helper'

class TestLibrary < Minitest::Test
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
        result = @library.stub :compile_template_from_source, @template do
          @library.get_rendered_template '', @context
        end

        assert_equal '{}', result
      end

      it 'uses for from lookup context' do
        context = Context.new(:xml)
        result = @library.stub :compile_template_from_source, @template do
          RablRails::Renderers::XML.stub :render, '<xml>' do
            @library.get_rendered_template '', context
          end
        end

        assert_equal '<xml>', result
      end

      it 'raises if format is not supported' do
        context = Context.new(:unsupported)
        @library.stub :compile_template_from_source, @template do
          assert_raises(RablRails::Library::UnknownFormat) { @library.get_rendered_template '', context }
        end
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
        with_configuration :cache_templates, false do
          @library.compile_template_from_source("attribute :id", @context)
        end

        assert_empty @library.cached_templates
      end

      it 'caches multiple templates in one compilation' do
        @context.virtual_path = 'users/show'
        with_configuration :cache_templates, true do
          @library.stub :fetch_source, 'attributes :id' do
            @library.compile_template_from_source("child(:account, partial: 'users/_account')", @context)
          end
        end

        assert_equal 2, @library.cached_templates.size
      end
    end
  end
end
