require 'test_helper'

class TestCompiledTemplate < ActiveSupport::TestCase

  setup do
    @context = Context.new
    @user = User.new
    @context.set_assign('user', @user)
    @template = RablFastJson::CompiledTemplate.new
    @template.context = @context
  end
end