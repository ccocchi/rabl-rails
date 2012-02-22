require 'test_helper'

class CompilerTest < ActiveSupport::TestCase
  class Context
    attr_accessor :virtual_path

    def initialize
      @_assigns = {}
      @virtual_path = '/users'
    end

    def set_assign(key, value)
      @_assigns[key] = value
    end

    def get_assign(key)
      @_assigns[key]
    end
  end

  class User
  end

  setup do
    @context = Context.new
    @user = User.new
    @context.set_assign('user', @user)
    @compiler = RablFastJson::Compiler.new(@context)
  end

  test "assigns are correctly imported from context" do
    assert_equal @user, @compiler.instance_variable_get(:@user)
  end

  test "virtual path is correctly imported from context" do
    assert_equal '/users', @compiler.instance_variable_get(:@virtual_path)
  end

  test "compiler return a compiled template" do
    assert_instance_of RablFastJson::CompiledTemplate, @compiler.compile_source("")
  end

  test "simple attributes are compiled to hash" do
    t = @compiler.compile_source(%{ attributes :id, :name })
    assert_equal({ :id => :id, :name => :name}, t.source)
  end

  test "attributes appeared only once even if called mutiple times" do
    t = @compiler.compile_source(%{ attribute :id ; attribute :id })
    assert_equal({ :id => :id }, t.source)
  end

  test "attribute can be aliased" do
    t = @compiler.compile_source(%{ attribute :foo => :bar })
    assert_equal({ :bar => :foo }, t.source)
  end

  test "multiple attributes can be aliased" do
    t = @compiler.compile_source(%{ attributes :foo => :bar, :id => :uid })
    assert_equal({ :bar => :foo, :uid => :id }, t.source)
  end
end