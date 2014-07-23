module RablRails
  #
  # Override default responder's api behavior to not
  # user to_format methods on a resource as a default
  # representation but instead use a rabl template
  #
  class Responder < ActionController::Responder
    def initialize(controller, resources, options = {})
      super
      if options[:locals]
        options[:locals][:resource] = resource
      else
        options[:locals] = { resource: resource }
      end
    end

    def to_format
      if get? || response_overridden?
        default_render
      elsif has_errors?
        display_errors
      else
        api_behavior(nil)
      end
    end

    protected

    def api_behavior(error)
      if post?
        template = if controller.respond_to?(:responder_default_template, true)
          controller.send(:responder_default_template)
        else
          RablRails.configuration.responder_default_template
        end
        options[:prefixes] = controller._prefixes
        options[:template] ||= template

        controller.default_render options.merge(status: :created)
      else
        head :no_content
      end
    rescue ActionView::MissingTemplate => e
      super(e)
    end
  end
end