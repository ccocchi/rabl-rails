require 'test_helper'

class NonRestfulResponseTest < ActiveSupport::TestCase
  setup do
    RablRails::Library.reset_instance

    @user = User.new(1, 'foo', 'male')
    @user.stub_chain(:posts, :count).and_return(10)
    @user.stub(:respond_to?).with(:each).and_return(false)

    @context = Context.new
    @context.stub(:instance_variable_get).with(:@user).and_return(@user)
    @context.stub(:instance_variable_get).with(:@virtual_path).and_return('user/show')
    @context.stub(:instance_variable_get).with(:@_assigns).and_return({'user' => @user})
    @context.stub(:lookup_context)
  end

  test "compile and render non restful resource" do
    source = %{
      object false
      node(:post_count) { @user.posts.count }
      child(:@user => :user) do
        attributes :id, :name
      end
    }

    assert_equal(ActiveSupport::JSON.encode({
      :post_count => 10,
      :user => {
        :id => 1,
        :name => 'foo'
      }
    }), RablRails::Library.instance.get_rendered_template(source, @context))
  end
end