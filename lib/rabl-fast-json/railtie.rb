module RablFastJson
  class Railtie < Rails::Railtie
    initializer "rabl.initialize" do |app|
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :rabl2, RablFastJson::Handlers::Rabl
      end
    end
  end
end