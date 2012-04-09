require 'test_helper'

class CacheTemplatesTest < ActiveSupport::TestCase

  setup do
    RablFastJson::Library.reset_instance
    @library = RablFastJson::Library.instance
    RablFastJson.cache_templates = true
  end

  test "cache templates if perform_caching is active and cache_templates is enabled" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    @library.get_compiled_template('some/path', "")
    t = @library.get_compiled_template('some/path', "attribute :id")

    assert_equal({}, t.source)
  end

  test "cached templates should not be modifiable in place" do
    ActionController::Base.stub(:perform_caching).and_return(true)
    t = @library.get_compiled_template('some/path', "")
    assert_nil t.context
    t.context = "foobar"
    assert_nil @library.get_compiled_template('some/path', "").context
  end

  test "don't cache templates cache_templates is enabled but perform_caching is not active" do
    ActionController::Base.stub(:perform_caching).and_return(false)
    @library.get_compiled_template('some/path', "")
    t = @library.get_compiled_template('some/path', "attribute :id")

    assert_equal({ :id => :id }, t.source)
  end
end