require 'test_helper'
require 'pathname'
require 'tmpdir'

class RenderTest < ActiveSupport::TestCase

  setup do
    @user = User.new(1, 'Marty')
    @tmp_path = Pathname.new(Dir.mktmpdir)
  end

  test "allow object to be passed as an option" do
    File.open(@tmp_path + "nil.json.rabl", "w") do |f|
      f.puts %q{
        object :@user
        attributes :name
      }
    end
    assert_equal %q({"user":{"name":"Marty"}}), RablRails.render(nil, 'nil', locals: { object: @user }, view_path: @tmp_path)
  end

  test "load source from file" do
    File.open(@tmp_path + "show.json.rabl", "w") do |f|
      f.puts %q{
        object :@user
        attributes :id, :name
      }
    end
    assert_equal %q({"user":{"id":1,"name":"Marty"}}), RablRails.render(@user, 'show', view_path: @tmp_path)
  end

  test "raise error if template is not found" do
    assert_raises(RablRails::Renderer::TemplateNotFound) { RablRails.render(@user, 'not_found') }
  end

  test "instance variables can be passed via options[:locals]" do
    File.open(@tmp_path + "instance.json.rabl", "w") do |f|
      f.puts %q{
        object false
        node(:username) { |_| @user.name }
      }
    end
    assert_equal %q({"username":"Marty"}), RablRails.render(nil, 'instance', view_path: @tmp_path, locals: { user: @user })
  end

  test "handle path for extends" do
    File.open(@tmp_path + "extend.json.rabl", "w") do |f|
      f.puts %q{
        object :@user
        extends 'base'
      }
    end

    File.open(@tmp_path + "base.json.rabl", "w") do |f|
      f.puts %q{
        attribute :name, as: :extended_name
      }
    end

    assert_equal %q({"user":{"extended_name":"Marty"}}), RablRails.render(@user, 'extend', view_path: @tmp_path)
  end

end