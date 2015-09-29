module RablRails
  class Railtie < Rails::Railtie
    initializer 'rabl.actionview' do
      ActionView::Template.register_template_handler :rabl, RablRails::Handlers::Rabl
    end
    config.after_initialize do
      ActionController::Base.responder = RablRails::Responder if RablRails.configuration.use_custom_responder
    end
  end
end