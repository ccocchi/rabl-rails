module RablRails
  class Railtie < Rails::Railtie
    initializer "rabl.initialize" do |app|
      RablRails.load_default_engines!
      
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :rabl, RablRails::Handlers::Rabl
      end
    end
  end
end