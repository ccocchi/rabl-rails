# RABL for Rails [![Build Status](https://travis-ci.org/ccocchi/rabl-rails.svg?branch=master)](https://travis-ci.org/ccocchi/rabl-rails)

`rabl-rails` is a ruby templating system for rendering your objects in different format (JSON, XML, PLIST).

This gem aims for speed and little memory footprint while letting you build complex response with a very intuitive DSL.

`rabl-rails` targets **Rails 4.2/5/6 application** and have been testing with MRI and jRuby.

## Installation

Install as a gem :

```
gem install rabl-rails
```

or add directly to your `Gemfile`

```
gem 'rabl-rails', '~> 0.6.0'
```

## Overview

The gem enables you to build responses using views like you would using HTML/erb/haml.
As example, assuming you have a `Post` model filled with blog posts, and a `PostController` that look like this:

```ruby
class PostController < ApplicationController
  def index
	 @posts = Post.order('created_at DESC')
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

## How it works

This gem separates compiling, ie. transforming a RABL-rails template into a Ruby hash, and the actual rendering of the object or collection. This allows to only compile the template once (when template caching is enabled) which is the slow part, and only use hashes during rendering.

The drawback of compiling the template outside of any rendering context is that we can't access instance variables like usual. Instead, you'll mostly use symbols representing your variables and the gem will retrieve them when needed.

There are places where the gem allows for "dynamic code" -- code that is evaluated at each rendering, such as within `node` or `condition` blocks.

```ruby
# We reference the @posts varibles that will be used at rendering time
collection :@posts

# Here you can use directly the instance variable because it
# will be evaluated when rendering the object
node(:read) { |post| post.read_by?(@user) }
```

The same rule applies for view helpers such as `current_user`

After the template is compiled into a hash, `rabl-rails` will use a renderer to create the actual output. Currently, JSON, XML and PList formats are supported.

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

There are rares cases when the template doesn't map directly to any object. In these cases, you can set data to false.

```ruby
object false
node(:some_count) { |_| @user.posts.count }
child(:@user) { attribute :name }
```

If you use gems like *decent_exposure* or *focused_controller*, you can use your variable directly without the leading `@`

```ruby
object :object_exposed
```

### Attributes / Methods

Adds a new field to the response object, calling the method on the object being rendered. Methods called this way should return natives types from the format you're using (such as `String`, `integer`, etc for JSON). For more complex objects, see `child` nodes.

```ruby
attributes :id, :title, :to_s
```

You can aliases these attributes in your response

```ruby
attributes :my_custom_method, as: :title
# => { "title" : <result of my_custom_method> }
```

or show attributes based on a condition. The currently rendered object is given to the `proc` condition.

```ruby
attributes :published_at, :anchor, if: ->(post) { post.published? }
```

### Child nodes

Changes the object being rendered for the duration of the block. Depending on if you use `node` or `glue`, the result will be added as a new field or merged respectively.

Data passed can be a method or a reference to an instance variable.

For example if you have a `Post` model that belongs to a `User` and want to add the user's name to your response.

```ruby
object :@post

child(:user, as: :author) do
	attributes :name
end
# => { "post": { "author" : { "name" : "John D." } } }
```

If instead of having an `author` node in your response you wanted the name at the root level, you can use `glue`:

```ruby
object :@post

glue(:user) do
  attributes :name, as: :author_name
end
# => { "post": { "author_name" : "John D." } }
```

Arbitrary data source can also be passed:

```ruby
# in your controller
# @custom_data = [...]

# in the view
child(:@custom_data) do
	attributes :id, :name
end
# => { "custom_data": [...] }
```

You can use a Hash-like data source, as long as keys match a method or attribute of your main resource, using the `fetch` keyword:

```ruby
# assuming you have something similar in your controller
# @users_hash = { 1 => User.new(pseudo: 'Batman') }

# in the view
object :@post

fetch(:@users_hash, as: :user, field: :user_id) do
  attributes :pseudo
end
# => { user: { pseudo: 'Batman' } }
```

This comes very handy when adding attributes from external queries not really bound to a relation, like statistics.

### Constants

Adds a new field to the response using an immutable value.

```ruby
const(:api_version, API::VERSION)
const(:locale, 'fr_FR')
```

### Lookups

Adds a new field to the response, using rendered resource's id by default or any method to fetch a value from the given hash variable.

```ruby
collection :@posts

lookup(:comments_count, :@comments_count, field: :uuid, cast: false)
# => [{ "comments_count": 3 }, { "comments_count": 6 }]
```

In the example above, for each post it will fetch the value from `@comments_count` using the post's `uuid` as key. When the `cast` value is set to `true` (it is `false` by default), the value will be casted to a boolean using `!!`.


### Custom nodes

Adds a new field to the response with block's result as value.

```ruby
object :@user
node(:full_name) { |u| u.first_name + " " + u.last_name }
# => { "user" : { "full_name" : "John Doe" } }
```

You can add condition on your custom nodes. If the condition evaluates to a falsey value, the node will not added to the response at all.

```ruby
node(:email, if: ->(u) { u.valid_email? }) do |u|
	u.email
end
```

Nodes are evaluated at rendering time, so you can use any instance variables or view helpers within them

```ruby
node(:url) { |post| post_url(post) }
```

If the result of the block is a Hash, it can be directly merge into the response using `merge` instead of `node`

```ruby
object :@user
merge { |u| { name: u.first_name + " " + u.last_name } }
# => { "user" : { "name" : "John Doe" } }
```

### Extends & Partials

Often objects have a basic representation that is shared accross different views and enriched according to it. To avoid code redundancy you can extend your template from any other RABL template.

```ruby
# app/views/shared/_user.rabl
attributes :id, :name

# app/views/users/show.rabl
object :@user

extends('shared/_user')
attributes :super_secret_attribute

#=> { "id": 1, "name": "John", "super_secret_attribute": "Doe" }
```

When used with child node, if they are the only thing added you can instead use the `partial` option directly.

```ruby
child(:user, partial: 'shared/_user')

# is equivalent to

child(:user) do
  extends('shared/_user')
end
```

Extends can be used dynamically using rendered object and lambdas.

```ruby
extends ->(user) { "shared/_#{user.client_type}_infos" }
```

Partials can also be used inside custom nodes. When using partial this way, you MUST declare the `object` associated to the partial

```ruby
node(:location) do |user|
	{ city: user.city, address: partial('users/address', object: m.address) }
end
```

When used this way, partials can take locals variables that can be accessed in the included template.

```ruby
# _credit_card.rabl
node(:credit_card, if: ->(u) { locals[:display_credit_card] }) do |user|
  user.credit_card_info
end

# user.json.rabl
merge { |u| partial('_credit_card', object: u, locals: { display_credit_card: true }) }
```

### Putting it all together

`rabl-rails` allows you to format your responses easily, from simple objects to hierarchy of 2 or 3 levels.

```ruby
object :@thread

attribute :caption, as: :title

child(:@sorted_posts, as: :posts) do
  attributes :title, :slug

  child :comments do
		extends 'shared/_comment'
    lookup(:upvotes, :@upvotes_per_comment)
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

Copyright © 2012-2020 Christopher Cocchi-Perrier. See [MIT-LICENSE](http://github.com/ccocchi/rabl-rails/blob/master/MIT-LICENSE) for details.
