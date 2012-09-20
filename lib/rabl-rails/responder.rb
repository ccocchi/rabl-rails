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

    protected

    def api_behavior(error)
      template = @controller.respond_to?(:responder_default_template, true) ? controller.send(:responder_default_template)
                                                                            : RablRails.responder_default_template
      rabl_options = options.merge(template: template)

      if get?
        controller.default_render rabl_options
      elsif post?
        controller.default_render rabl_options.merge!(status: :created, location: api_location)
      else
        head :no_content
      end
    end
  end
end