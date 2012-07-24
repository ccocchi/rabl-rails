require 'rabl-rails/renderers/base'
require 'rabl-rails/renderers/json'

module Renderer
  mattr_reader :view_path
  @@view_path = 'app/views'
  
  def render(object, template, options = {})
    format = options.delete(:format) || 'json'
    source = find_template(template, format, options.delete(:view_path))
    compiled_template = Compiler.new.compile_source(source)
    
    # TODO: context needs to be set from options
    Renderers.const_get(format.upcase!).new(context).render(compiled_template)
  end
  
  private
  
  def find_template(name, format, view_path = nil)
    view_path ||= self.view_path
    path = File.join(view_path, "#{name}.#{format}.rabl")
    File.exists?(path) : File.read(path) : nil
  end
end