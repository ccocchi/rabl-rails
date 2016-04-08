require 'helper'
require 'set'

class TestHelpers < MINITEST_TEST_CLASS
  include RablRails::Helpers

  def test_collection_with_default
    assert collection?(['foo'])
    refute collection?(User.new(1))
  end

  ACollection = Class.new(Array) do
    def each; end
  end

  def test_collection_with_configuration
    assert collection?(ACollection.new)

    with_configuration(:non_collection_classes, Set.new(['Struct', 'TestHelpers::ACollection'])) do
      refute collection?(ACollection.new), 'Collection triggers #collection?'
    end
  end
end