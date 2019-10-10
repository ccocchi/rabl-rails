module RablRails
  module Inline
    View = Struct.new(:lookup_context)

    class ViewContext
      def initialize
        @_assigns = {}
      end
    end

    def self.render(object_or_collection, path, lookup_context: nil)
      if !lookup_context
        view_paths      = ActionController::Base.view_paths
        lookup_context  = ActionView::LookupContext.new(view_paths)
      end

      view = View.new(lookup_context)
      compiled_template = RablRails::Library.instance.compile_template_from_path(
        path,
        view
      )

      RablRails::Renderers::Hash.inline_render(
        compiled_template,
        object_or_collection,
        ViewContext.new
      )
    end
  end
end
