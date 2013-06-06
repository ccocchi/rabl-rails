require 'test_helper'

class CompilerTest < ActiveSupport::TestCase

  setup do
    @user = User.new
    @compiler = RablRails::Compiler.new
  end

  test "compiler return a compiled template" do
    assert_instance_of RablRails::CompiledTemplate, @compiler.compile_source("")
  end

  test "object set data for the template" do
    t = @compiler.compile_source(%{ object :@user })
    assert_equal :@user, t.data
    assert_equal({}, t.source)
  end

  test "object property can define root name" do
    t = @compiler.compile_source(%{ object :@user => :author })
    assert_equal :@user, t.data
    assert_equal :author, t.root_name
    assert_equal({}, t.source)
  end

  test "root can be defined via keyword" do
    t = @compiler.compile_source(%{ root :author })
    assert_equal :author, t.root_name
  end

  test "root keyword override object root" do
    t = @compiler.compile_source(%{ object :@user ; root :author })
    assert_equal :author, t.root_name
  end

  test "collection set the data for the template" do
    t = @compiler.compile_source(%{ collection :@user })
    assert_equal :@user, t.data
    assert_equal({}, t.source)
  end

  test "collection property can define root name" do
    t = @compiler.compile_source(%{ collection :@user => :users })
    assert_equal :@user, t.data
    assert_equal :users, t.root_name
    assert_equal({}, t.source)
  end

  test "collection property can define root name via options" do
    t = @compiler.compile_source(%{ collection :@user, :root => :users })
    assert_equal :@user, t.data
    assert_equal :users, t.root_name
  end

  test "root can be set to false via options" do
    t = @compiler.compile_source(%( object :@user, root: false))
    assert_equal false, t.root_name
  end

  test "template should not have a cache key if cache is not enable" do
    t = @compiler.compile_source('')
    assert_equal false, t.cache_key
  end

  test "cache can take no argument" do
    t = @compiler.compile_source(%{ cache })
    assert_nil t.cache_key
  end

  test "cache can take a block" do
    t = @compiler.compile_source(%( cache { 'foo' }))
    assert_instance_of Proc, t.cache_key
  end

  # Compilation

  test "simple attributes are compiled to hash" do
    t = @compiler.compile_source(%{ attributes :id, :name })
    assert_equal({ :id => :id, :name => :name}, t.source)
  end

  test "attributes appeared only once even if called mutiple times" do
    t = @compiler.compile_source(%{ attribute :id ; attribute :id })
    assert_equal({ :id => :id }, t.source)
  end

  test "attribute can be aliased through :as option" do
    t = @compiler.compile_source(%{ attribute :foo, :as => :bar })
    assert_equal({ :bar => :foo}, t.source)
  end

  test "attribute can be aliased through hash" do
    t = @compiler.compile_source(%{ attribute :foo => :bar })
    assert_equal({ :bar => :foo }, t.source)
  end

  test "multiple attributes can be aliased" do
    t = @compiler.compile_source(%{ attributes :foo => :bar, :id => :uid })
    assert_equal({ :bar => :foo, :uid => :id }, t.source)
  end

  test "child with association use association name as data" do
    t = @compiler.compile_source(%{ child :address do attributes :foo end})
    assert_equal({ :address => { :_data => :address, :foo => :foo } }, t.source)
  end

  test "child with association can be aliased" do
    t = @compiler.compile_source(%{ child :address => :bar do attributes :foo end})
    assert_equal({ :bar => { :_data => :address, :foo => :foo } }, t.source)
  end

  test "child with root name defined as option" do
    t = @compiler.compile_source(%{ child(:user, :root => :author) do attributes :foo end })
    assert_equal({ :author => { :_data => :user, :foo => :foo } }, t.source)
  end

  test "child with arbitrary source store the data with the template" do
    t = @compiler.compile_source(%{ child :@user => :author do attribute :name end })
    assert_equal({ :author => { :_data => :@user, :name => :name } }, t.source)
  end

  test "child with succint partial notation" do
    mock_template = RablRails::CompiledTemplate.new
    mock_template.source = { :id => :id }
    RablRails::Library.reset_instance
    RablRails::Library.instance.stub(:compile_template_from_path).with('users/base').and_return(mock_template)

    t = @compiler.compile_source(%{child(:user, :partial => 'users/base') })
    assert_equal({:user => { :_data => :user, :id => :id } }, t.source)
  end

  test "glue is compiled as a child but with anonymous name" do
    t = @compiler.compile_source(%{ glue(:@user) do attribute :name end })
    assert_equal({ :_glue0 => { :_data => :@user, :name => :name } }, t.source)
  end

  test "multiple glue don't come with name collisions" do
    t = @compiler.compile_source(%{
      glue :@user do attribute :name end
      glue :@user do attribute :foo end
    })

    assert_equal({
      :_glue0 => { :_data => :@user, :name => :name},
      :_glue1 => { :_data => :@user, :foo => :foo}
    }, t.source)
  end

  test "glue accepts all dsl in its body" do
    t = @compiler.compile_source(%{
      glue :@user do node(:foo) { |u| u.name } end
    })

    assert_not_nil(t.source[:_glue0])
    s = t.source[:_glue0]

    assert_equal(:@user, s[:_data])
    assert_instance_of(Proc, s[:foo])
  end

  test "extends use other template source as itself" do
    template = mock('template', :source => { :id => :id })
    RablRails::Library.reset_instance
    RablRails::Library.instance.stub(:compile_template_from_path).with('users/base').and_return(template)
    t = @compiler.compile_source(%{ extends 'users/base' })
    assert_equal({ :id => :id }, t.source)
  end

  test "extends should not overwrite nodes previously defined" do
    skip('Bug reported by @abrisse')

    template = mock('file_template', :source => %(condition(-> { true }) { 'foo' }))
    lookup_context = mock
    lookup_context.stub(:find_template).with('users/xtnd', [], false).and_return(template)
    RablRails::Library.reset_instance
    RablRails::Library.instance.instance_variable_set(:@lookup_context, lookup_context)

    t = @compiler.compile_source(%{
      condition(-> { false }) { 'bar' }
      extends('users/xtnd')
    })

    assert_equal 2, t.source.keys.size
  end

  test "node are compiled without evaluating the block" do
    t = @compiler.compile_source(%{ node(:foo) { bar } })
    assert_not_nil t.source[:foo]
    assert_instance_of Proc, t.source[:foo]
  end

  test "node with condition are compiled as an array of procs" do
    t = @compiler.compile_source(%{ node(:foo, :if => lambda { |m| m.foo.present? }) do |m| m.foo end })
    assert_not_nil t.source[:foo]
    assert_instance_of Array, t.source[:foo]
    assert_equal 2, t.source[:foo].size
  end

  test "node can take no arguments and behave like a merge" do
    t = @compiler.compile_source(%{ node do |m| m.foo end })
    assert_instance_of Proc, t.source[:_merge0]
  end

  test "merge compile like a node but with a reserved keyword as name" do
    t = @compiler.compile_source(%{ merge do |m| m.foo end })
    assert_instance_of Proc, t.source[:_merge0]
  end

  test "conditionnal block compile nicely" do
    t = @compiler.compile_source(%{ condition(->(u) {}) do attributes :secret end })
    assert_instance_of RablRails::Condition, t.source[:_if0]
    assert_equal({ :secret => :secret }, t.source[:_if0].source)
  end

  test "compile with no object" do
    t = @compiler.compile_source(%{
     object false
     child(:@user => :user) do
       attribute :id
     end
    })

    assert_equal({ :user => { :_data => :@user, :id => :id } }, t.source)
    assert_equal false, t.data
  end

  test "name extraction from argument" do
    assert_equal [:@users, 'users'], @compiler.send(:extract_data_and_name, :@users)
    assert_equal [:users, :users], @compiler.send(:extract_data_and_name, :users)
    assert_equal [:@users, :authors], @compiler.send(:extract_data_and_name, :@users => :authors)
  end
end