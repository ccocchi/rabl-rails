module RablRails
  class Railtie < Rails::Railtie
    initializer "rabl.initialize" do |app|
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :rabl, RablRails::Handlers::Rabl
      end
      ActiveSupport.on_load :action_controller do
        self.responder = RablRails::Responder if RablRails.configuration.use_custom_responder
      end
    end
  end
end