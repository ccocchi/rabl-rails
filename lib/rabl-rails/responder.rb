module RablRails
  #
  # Override default responder's api behavior to not
  # user to_format methods on a resource as a default
  # representation but instead use a rabl template
  #
  class Responder < ActionController::Responder
    protected

    def api_behavior(error)
      rabl_options = options.merge(template: RablRails.responder_default_template)

      if get?
        controller.default_render rabl_options
      elsif post?
        controller.default_render rabl_options.merge!(status: :created, location: api_location, locals: { resource: resource })
      else
        head :no_content
      end
    end
  end
end