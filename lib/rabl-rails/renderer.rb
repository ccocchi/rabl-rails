require 'rabl-rails/renderers/base'
require 'rabl-rails/renderers/json'
require 'rabl-rails/renderers/xml'
require 'rabl-rails/renderers/plist'

module RablRails
  module Renderer
    class TemplateNotFound < StandardError; end

    mattr_reader :view_path
    @@view_path = 'app/views'

    class LookupContext
      T = Struct.new(:source)

      def initialize(view_path, format)
        @view_path = view_path || RablRails::Renderer.view_path
        @format = format.to_s.downcase
      end

      #
      # Manually find given rabl template file with given name.
      # View path can be set via options, otherwise default Rails
      # path is used
      #
      def find_template(name, opt, partial = false)
        path = _find_template([name, :rabl].join('.'))
        path = find_legacy_template(name) unless path

        T.new(File.read(path)) if path
      end

      private

      # Find legacy .json.rabl templates and prints a deprecation
      # warning asking the user to rename them.
      def find_legacy_template(name)
        _find_template([name, @format, :rabl].join('.')).tap do |path|
          if path
            ActiveSupport::Deprecation.warn(
              ".#@format.rabl templates are deprecated. " \
              "Please rename #@view_path/#{name}.#@format.rabl as #{name}.rabl")
          end
        end
      end

      def _find_template(name)
        path = File.join(@view_path, name)
        return path if File.exists?(path)
      end
    end

    #
    # Context class to emulate normal Rails view
    # context
    #
    class Context
      attr_reader :format

      def initialize(path, options)
        @virtual_path = path
        @format = options.delete(:format) || 'json'
        @_assigns = {}
        @options = options

        options[:locals].each { |k, v| @_assigns[k.to_s] = v } if options[:locals]
      end

      def assigns
        @_assigns
      end

      def params
        { format: format }
      end

      def lookup_context
        @lookup_context ||= LookupContext.new(@options[:view_path], format)
      end
    end

    #
    # Renders object with the given rabl template.
    #
    # Object can also be passed as an option :
    # { locals: { object: obj_to_render } }
    #
    # Default render format is JSON, but can be changed via
    # an option: { format: 'xml' }
    #
    # If template includes uses of instance variables (usually
    # defined in the controller), you can passed them as locals
    # options.
    # For example, if you have this template:
    #   object :@user
    #   node(:read) { |u| u.has_read?(@post) }
    #
    # Your method call should look like this:
    #   RablRails.render(user, 'users/show', locals: { post: Post.new })
    #
    def render(object, template, options = {})
      object = options[:locals].delete(:object) if !object && options[:locals]

      c = Context.new(template, options)
      t = c.lookup_context.find_template(template, [], false)

      raise TemplateNotFound unless t

      Library.instance.get_rendered_template(t.source, c, resource: object)
    end
  end
end
