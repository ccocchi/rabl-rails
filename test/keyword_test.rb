require 'test_helper'

class KeywordTest < ActiveSupport::TestCase
  class Collection
    attr_accessor :id, :name

    def initialize(id, name)
      @id   = id
      @name = name
    end

    def cover(size)
      "foo_#{size}"
    end
  end

  setup do
    RablRails::Library.reset_instance
    @context = Context.new
    @user = User.new(1, 'Marty')
    @collections = [Collection.new(1, 'first'), Collection.new(2, 'last')]
    @context.assigns['user'] = @user
    @context.assigns['collections'] = @collections
    @context.virtual_path = 'user/show'
    @context.stub(lookup_context: nil)
  end

  test "collections model should render correctly" do
    source = %{
      object :@user
      child(:@collections => :collections) do
        attributes :id, :name
        node(:cover_url) { |c|
          c.cover(:medium)
        }
      end
    }

    assert_equal(MultiJson.encode(
      user: { collections: [{
        id: 1, name: 'first', cover_url: "foo_medium"
      }, {
        id: 2, name: 'last', cover_url: "foo_medium"
      }] }
    ), RablRails::Library.instance.get_rendered_template(source, @context))
  end
end