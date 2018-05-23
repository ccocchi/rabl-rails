require 'ruby-prof'
require 'rabl-rails'
require 'action_controller'
require 'oj'

RablRails.configure do |config|
  config.cache_templates = true
end

source = <<-STR
  attributes :size
  attributes :size, as: :foo
  attributes :size, as: :bar
STR

class A
  def initialize
    @_assigns = {}
  end

  def data
    [[1, 2, 3]]
  end

  def params
    {}
  end
end
view = A.new

template = RablRails::Compiler.new(view).compile_source(source)
template.data = :data

puts RablRails::Renderers::JSON.render(template, view, nil)

RubyProf.start

# 100.times {
  RablRails::Renderers::JSON.render(template, view, nil)
# }

result = RubyProf.stop

# print a flat profile to text
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
