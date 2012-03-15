require 'test_helper'

class DeepNestingTest < ActiveSupport::TestCase

  class Post
    attr_accessor :id, :title

    def initialize(id, title)
      @id, @title = id, title
    end

    def comments
      [Struct.new(:id, :content).new(1, 'first'), Struct.new(:id, :content).new(2, 'second')]
    end
  end

  setup do
    RablFastJson::Library.reset_instance
    @post = Post.new(42, 'I rock !')
    @user = User.new(1, 'foobar', 'male')
    @user.stub(:posts).and_return([@post])
    @user.stub(:respond_to?).with(:each).and_return(false)

    @view_renderer = mock()
    @view_renderer.stub_chain(:lookup_context, :find_template).with('comments/show', [], false).and_return(
      mock(:source => %{ object :@comment\n attribute :content }))

    @context = Context.new
    @context.stub(:instance_variable_get).with(:@user).and_return(@user)
    @context.stub(:instance_variable_get).with(:@view_renderer).and_return(@view_renderer)
    @context.stub(:instance_variable_get).with(:@virtual_path).and_return('users/show')
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({})
  end

  test "compile and render deep nesting template" do
    source = %{
      object :@user
      attributes :id, :name
      child :posts do
        attribute :title
        child :comments do
          extends 'comments/show'
        end
      end
    }

    assert_equal(ActiveSupport::JSON.encode({
      :id => 1,
      :name => 'foobar',
      :posts => [{
        :title => 'I rock !',
        :comments => [
          { :content => 'first' },
          { :content => 'second' }
        ]
      }]
    }), RablFastJson::Library.instance.get_rendered_template(source, @context))
  end
end



