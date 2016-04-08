require 'helper'
require 'set'

class TestHelpers < Minitest::Test
  include RablRails::Helpers

  def test_collection_with_default
    assert collection?(['foo'])
    refute collection?(User.new(1))
  end

  NotACollection = Class.new do
    def each; end
  end

  def test_collection_with_configuration
    assert collection?(NotACollection.new)

    with_configuration(:non_collection_classes, Set.new(['Struct', 'TestHelpers::NotACollection'])) do
      refute collection?(NotACollection.new), 'NotACollection triggers #collection?'
    end
  end
end