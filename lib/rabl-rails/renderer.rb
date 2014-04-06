require 'rabl-rails/renderers/hash'
require 'rabl-rails/renderers/json'
require 'rabl-rails/renderers/xml'
require 'rabl-rails/renderers/plist'

module RablRails
  module Renderer
    class TemplateNotFound < StandardError; end
    class PartialError < StandardError; end

    class LookupContext
      T = Struct.new(:source)

      def initialize(view_path, format)
        @view_path = view_path || 'app/views'
        @extension = format ? ".#{format.to_s.downcase}.rabl" : ".rabl"
      end

      #
      # Manually find given rabl template file with given format.
      # View path can be set via options, otherwise default Rails
      # path is used
      #
      def find_template(name, opt, partial = false)
        path = File.join(@view_path, "#{name}#{@extension}")
        File.exists?(path) ? T.new(File.read(path)) : nil
      end
    end

    #
    # Context class to emulate normal Rails view
    # context
    #
    class ViewContext
      attr_reader :format

      def initialize(path, options)
        @virtual_path = path
        @format = options.delete(:format) || (RablRails.configuration.allow_empty_format_in_template ? nil : 'json')
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

      c = ViewContext.new(template, options)
      t = c.lookup_context.find_template(template, [], false)

      raise TemplateNotFound unless t

      Library.instance.get_rendered_template(t.source, c, resource: object)
    end
  end
end