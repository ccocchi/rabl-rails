require 'test_helper'

class TestBaseRenderer < ActiveSupport::TestCase

  RablRails::Renderers::Base.class_eval do
    def format_output(hash)
      hash
    end
  end

  setup do
    @data = User.new(1, 'foobar', 'male')

    @context = Context.new
    @context.assigns['data'] = @data

    @template = RablRails::CompiledTemplate.new
    @template.data = :@data
  end

  teardown do
    RablRails.replace_nil_values_with_empty_strings = false
  end

  def render_hash
    RablRails::Renderers::Base.new(@context).render(@template)
  end

  test "child with nil data should render nil" do
    @template.source = { :author => { :_data => :@nil, :name => :name } }
    assert_equal({ :author => nil }, render_hash)
  end

  test "properly handles assigns with symbol keys" do
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({ :foo => "bar" })
    @template.source = { :author => { :_data => :@nil, :name => :name } }
    assert_nothing_raised do
      render_hash
    end
  end

  test "child with nil data should render empty string if replace_nil_values_with_empty_strings is set" do
    RablRails.replace_nil_values_with_empty_strings = true
    @template.source = { :author => { :_data => :@nil, :name => :name } }
    assert_equal({ :author => "" }, render_hash)
  end
end
