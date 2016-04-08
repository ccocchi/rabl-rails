require 'helper'

class TestConfiguration < Minitest::Test
  describe 'Configuration' do
    it 'has a zero score by default' do
      config = RablRails::Configuration.new
      assert_equal 0, config.result_flags
    end

    it 'sets a bit per option' do
      config = RablRails::Configuration.new
      config.replace_nil_values_with_empty_strings = true
      assert_equal 1, config.result_flags

      config = RablRails::Configuration.new
      config.replace_empty_string_values_with_nil = true
      assert_equal 2, config.result_flags

      config = RablRails::Configuration.new
      config.exclude_nil_values = true
      assert_equal 4, config.result_flags
    end

    it 'allows mutiple bits to be set at the same time' do
      config = RablRails::Configuration.new
      config.replace_nil_values_with_empty_strings = true
      config.replace_empty_string_values_with_nil = true
      assert_equal 3, config.result_flags
    end
  end
end
