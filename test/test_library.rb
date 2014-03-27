require 'test_helper'

class TestLibrary < ActiveSupport::TestCase

  setup do
    RablRails::Library.reset_instance
    @library = RablRails::Library.instance
    RablRails.cache_templates = true
  end

  # test "cache templates if perform_caching is active and cache_templates is enabled" do
  #   ActionController::Base.stub(:perform_caching).and_return(true)
  #   @library.compile_template_from_source('', 'some/path')
  #   t = @library.compile_template_from_source("attribute :id", 'some/path')

  #   assert_equal({}, t.source)
  # end

  # test "cached templates should not be modifiable in place" do
  #   ActionController::Base.stub(:perform_caching).and_return(true)
  #   t = @library.compile_template_from_source('', 'some/path')

  #   t.merge!(:_data => :foo)

  #   assert_equal({}, @library.compile_template_from_path('some/path').source)
  # end

  # test "don't cache templates cache_templates is enabled but perform_caching is not active" do
  #   ActionController::Base.stub(:perform_caching).and_return(false)
  #   @library.compile_template_from_source('', 'some/path')
  #   t = @library.compile_template_from_source("attribute :id", 'some/path')

  #   assert_equal({ :id => :id }, t.source)
  # end
end