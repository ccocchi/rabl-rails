require 'test_helper'

class CacheTemplatesTest < ActiveSupport::TestCase

  setup do
    RablFastJson::Library.reset_instance
    @library = RablFastJson::Library.instance 
  end
  
  test "cache templates if perform_caching is active and cache_templates is enabled" do
    RablFastJson.cache_templates = true
    ActionController::Base.stub(:perform_caching).and_return(true)    
    
    assert_equal @library.get_compiled_template('some/path', ""), @library.get_compiled_template('some/path', "")
  end
  
  test "don't cache templates cache_templates is enabled but perform_caching is not active" do
    RablFastJson.cache_templates = true
    ActionController::Base.stub(:perform_caching).and_return(false)    
    
    refute_equal @library.get_compiled_template('some/path', ""), @library.get_compiled_template('some/path', "")
  end
end