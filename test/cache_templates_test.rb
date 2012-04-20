require 'test_helper'

class CacheTemplatesTest < ActiveSupport::TestCase

  setup do
    RablRails::Library.reset_instance
    @library = RablRails::Library.instance
    RablRails.cache_templates = true
  end

  test "cache templates if perform_caching is active and cache_templates is enabled" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    @library.get_compiled_template('some/path', "")
    t = @library.get_compiled_template('some/path', "attribute :id")

    assert_equal({}, t.source)
  end

  test "cached templates should not be modifiable in place" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    @library.get_compiled_template('some/path', "")
    t = @library.get_compiled_template('some/path', "attribute :id")

    assert_equal({}, t.source)
  end

  test "don't cache templates cache_templates is enabled but perform_caching is not active" do
    ActionController::Base.stub(:perform_caching).and_return(false)
    @library.get_compiled_template('some/path', "")
    t = @library.get_compiled_template('some/path', "attribute :id")

    assert_equal({ :id => :id }, t.source)
  end
end