require 'helper'

class TestHelpers < MINITEST_TEST_CLASS
  include RablRails::Helpers

  def test_collection_with_default
    assert collection?(['foo'])
    refute collection?(User.new(1))
  end

  NotACollection = Class.new do
    def to_ary; end
  end

  def test_collection_with_configuration
    assert collection?(NotACollection.new)

    with_configuration(:non_collection_classes, [Struct, NotACollection]) do
      refute collection?(NotACollection.new)
    end
  end
end