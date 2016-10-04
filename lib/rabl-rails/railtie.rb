module RablRails
  class Railtie < Rails::Railtie
    initializer "rabl.initialize" do |app|
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :rabl, RablRails::Handlers::Rabl
      end
    end

    if Rails::VERSION::MAJOR >= 5
      module ::ActionController
        module ApiRendering
          include ActionView::Rendering
        end
      end

      ActiveSupport.on_load :action_controller do
        if self == ActionController::API
          include ActionController::Helpers
          include ActionController::ImplicitRender
        end
      end
    end

    config.after_initialize do
      ActionController::Base.responder = RablRails::Responder if RablRails.configuration.use_custom_responder
    end
  end
end
