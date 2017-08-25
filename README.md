# RABL for Rails [![Build Status](https://travis-ci.org/ccocchi/rabl-rails.png?branch=master)](https://travis-ci.org/ccocchi/rabl-rails)

RABL (Ruby API Builder Language) is a ruby templating system for rendering resources in different format (JSON, XML, BSON, ...). You can find documentation [here](http://github.com/nesquena/rabl).

rabl-rails is **faster** and uses **less memory** than the standard rabl gem while letting you access the same features. There are some slight changes to do on your templates to get this gem to work but it should't take you more than 5 minutes.

rabl-rails only targets **Rails 4.2+ application** and is compatible with mri 2.2+, jRuby and rubinius.

## Installation

Install as a gem :

```
gem install rabl-rails
```

or add directly to your `Gemfile`

```
gem 'rabl-rails'
```

And that's it !

## Overview

Once you have installed rabl-rails, you can directly used RABL-rails templates to render your resources without changing anything to you controller. As example,
assuming you have a `Post` model filled with blog posts, and a `PostController` that look like this :

```ruby
class PostController < ApplicationController
  respond_to :html, :json, :xml

  def index
	 @posts = Post.order('created_at DESC')
	  respond_with(@posts)
  end
end
```

You can create the following RABL-rails template to express the API output of `@posts`

```ruby
# app/views/post/index.rabl
collection :@posts
attributes :id, :title, :subject
child(:user) { attributes :full_name }
node(:read) { |post| post.read_by?(@user) }
```

This would output the following JSON when visiting `http://localhost:3000/posts.json`

```js
[{
  "id" : 5, title: "...", subject: "...",
  "user" : { full_name : "..." },
  "read" : true
}]
```

That's a basic overview but there is a lot more to see such as partials, inheritance or fragment caching.

## How it works

As opposed to standard RABL gem, this gem separate compiling (a.k.a transforming a RABL-rails template into a Ruby hash) and the actual rendering of the object or collection. This allow to only compile the template once and only Ruby hashes.

The fact of compiling the template outside of any rendering context prevent us to use any instances variables (with the exception of node) in the template because they are rendering objects. So instead, you'll have to use symbols of these variables.For example, to render the collection `@posts` inside your `PostController`, you need to use `:@posts` inside of the template.

The only places where you can actually used instance variables  are into Proc (or lambda) or into custom node (because they are treated as Proc).

```ruby
# We reference the @posts varibles that will be used at rendering time
collection :@posts

# Here you can use directly the instance variable because it
# will be evaluated when rendering the object
node(:read) { |post| post.read_by?(@user) }
```

The same rule applies for view helpers such as `current_user`

After the template is compiled into a hash, Rabl-rails will use a renderer to do the actual output. Actually, only JSON and XML formats are supported.

## Configuration

RablRails works out of the box, with default options and fastest engine available (oj, libxml). But depending on your needs, you might want to change that or how your output looks like. You can set global configuration in your application:

```ruby
# config/initializers/rabl_rails.rb
RablRails.configure do |config|
  # These are the default
  # config.cache_templates = true
  # config.include_json_root = true
  # config.json_engine = ::Oj
  # config.xml_options = { :dasherize => true, :skip_types => false }
  # config.enable_jsonp_callbacks = false
  # config.replace_nil_values_with_empty_strings = false
  # config.replace_empty_string_values_with_nil = false
  # config.exclude_nil_values = false
  # config.non_collection_classes = Set.new(['Struct'])
end
```

## Usage

### Data declaration

To declare data to use in the template, you can use either `object` or `collection` with the symbol name or your data.

```ruby
# app/views/users/show.json.rabl
object :@user

# app/views/users/index.json.rabl
collection :@users
```

You can specify root label for the collection using hash or `:root` option

```ruby
collection :@posts, root: :articles
#is equivalent to
collection :@posts => :articles

# => { "articles" : [{...}, {...}] }
```

There are rares cases when the template doesn't map directly to any object. In these cases, you can set data to false or skip data declaration altogether.

```ruby
object false
node(:some_count) { |_| @user.posts.count }
child(:@user) { attribute :name }
```

If you use gem like *decent_exposure* or *focused_controller*, you can use your variable directly without the leading `@`

```ruby
object :object_exposed
```

You can even skip data declaration at all. If you used `respond_with`, rabl-rails will render the data you passed to it.
As there is no name, you can set a root via the `root` macro. This allow you to use your template without caring about variables passed to it.

```ruby
# in controller
respond_with(@post)

# in rabl-rails template
root :article
attribute :title
```

### Attributes / Methods

Basic usage is to declared attributes to include in the response. These can be database attributes or any instance method.

```ruby
attributes :id, :title, :to_s
```

You can aliases these attributes in your response

```ruby
attributes title: :foo, to_s: :bar
# => { "foo" : <title value>, "bar" : <to_s value> }
```

or show attributes only if a condition is true
```ruby
attributes :published_at, :anchor, if: ->(post) { post.published? }
```

### Child nodes

You can include informations from data associated with the parent model or arbitrary data. These informations can be grouped under a node or directly merged into current node.

For example if you have a `Post` model that belongs to a `User`

```ruby
object :@post
child(user: :author) do
	attributes :name
end
# => { "post" : { "author" : { "name" : "John D." } } }
```

You can also use arbitrary data source with child nodes
```ruby
child(:@users) do
	attributes :id, :name
end
```

If you want to merge directly into current node, you can use the `glue` keywork

```ruby
attribute :title
glue(:user) do
  attributes :name => :author_name
end
# => { "post" : { "title" : "Foo", "author_name" : "John D." } }
```

### Custom nodes

You can create custom node in your response, based on the result of a given block

```ruby
object :@user
node(:full_name) { |u| u.first_name + " " + u.last_name }
# => { "user" : { "full_name" : "John Doe" } }
```

or with an assigned constant

```ruby
const(:api_version, API::VERSION)
const(:locale, 'fr_FR')
```

You can add condition on your custom nodes (if the condition is evaluated to false, the node will not be included).

```ruby
node(:email, if: ->(u) { u.valid_email? }) do |u|
	u.email
end
```

Nodes are evaluated at the rendering time, so you can use any instance variables or view helpers inside them

```ruby
node(:url) { |post| post_url(post) }
```

If you want to include directly the result into the current node, use the `merge` keyword (result returned from the block should be a hash)

```ruby
object :@user
merge { |u| { name: u.first_name + " " + u.last_name } }
# => { "user" : { "name" : "John Doe" } }
```

Custom nodes are really usefull to create flexible representations of your resources.

### Extends & Partials

Often objects have a basic representation that is shared accross different views and enriched according to it. To avoid code redundancy you can extend your template from any other RABL template.

```ruby
# app/views/users/base.json.rabl
attributes :id, :name

# app/views/users/private.json.rabl
attributes :super_secret_attribute

extends 'users/base'
# or using partial instead of extends
# merge { |u| partial('users/base', object: u) }
```

You can also extends template in child nodes using `partial` option (this is the same as using `extends` in the child block)

```ruby
collection @posts
attribute :title
child(:user, partial: 'users/base')
```

Partials can also be used inside custom nodes. When using partial this way, you MUST declare the object associated to the partial

```ruby
node(:location) do |user|
	{ city: user.city, address: partial('users/address', object: m.address) }
end
```

When used within `node`, partials can take locals variables that can be accessed in the included template.
```ruby
# base.json.rabl
node(:credit_card, if: ->(u) { locals[:display_credit_card] }) do |user|
  user.credit_card_info
end

# user.json.rabl
merge { |u| partial('users/base', object: u, locals: { display_credit_card: true }) }
```

### Nesting

Rabl allow you to define easily your templates, even with hierarchy of 2 or 3 levels. Let's suppose your have a `thread` model that has many `posts` and that each post has many `comments`. We can display a full thread in a few lines

```ruby
object :@thread
attribute :caption
child :posts do
  attribute :title
	child :comments do
		extends 'comments/base'
	end
end
```

### Other features

* [Caching](https://github.com/ccocchi/rabl-rails/wiki/Caching)

And more in the [WIKI](https://github.com/ccocchi/rabl-rails/wiki)

## Performance

Benchmarks have been made using this [application](http://github.com/ccocchi/rabl-benchmark), with rabl 0.13.1 and rabl-rails 0.5.0

Overall, rabl-rails is **10% faster and use 10% less memory**, but these numbers skyrockets to **50%** when using `extends` with collection of objects.

You can see full tests on test application repository.

## Authors and contributors

* [Christopher Cocchi-Perrier](http://github.com/ccocchi) - Creator of the project

Want to add another format to Rabl-rails ? Checkout [JSON renderer](http://github.com/ccocchi/rabl-rails/blob/master/lib/rabl-rails/renderers/json.rb) for reference
Want to make another change ? Just fork and contribute, any help is very much appreciated. If you found a bug, you can report it via the Github issues.

## Original idea

* [RABL](http://github.com/nesquena/rabl) Standart RABL gem. I used it a lot but I needed to improve my API response time, and since most of the time was spent in view rendering, I decided to implement a faster rabl gem.

## Copyright

Copyright © 2012-2017 Christopher Cocchi-Perrier. See [MIT-LICENSE](http://github.com/ccocchi/rabl-rails/blob/master/MIT-LICENSE) for details.
