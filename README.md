# RABL for Rails #

RABL (Ruby API Builder Language) is a ruby templating system for rendering resources in different format (JSON, XML, BSON, ...). You can find documentation [here](http://github.com/nesquena/rabl).

RABL-rails only target Rails 3+ application because Rails 2 applications are becoming less and less present and will be obsolete with Rails 4. So let's look to the future !

So now you ask why used `rabl-rails` if `rabl` already exists and supports Rails. Rabl-rails is **faster** and uses **less memory** than standard rabl gem while letting you access same features. Of course, there are some slight changes to do on your templates to get this gem to work but it should't take you more than 5 minutes.

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

Once you have installed RABL, you can directly used RABL templates to render your resources without changing anything to you controller. As example,
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

RablRails works out of the box, with default options and fastest engine available (yajl, libxml). But depending on your needs, you might want to change that or how your output looks like. You can set global configuration in your application:

```ruby
  # config/initializers/rabl_rails.rb
  RablRails.configure do |config|
    # These are the default
    # config.cache_templates = true
    # config.include_json_root = true
    # config.json_engine = :yajl
    # config.xml_engine = 'LibXML'
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

### Child nodes

You can include nested information from data associated with the parent model. You can also alias these associations.
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

### Custom nodes

You can create custom node in your response, based on the result of the given block

```ruby
object :@user
node(:full_name) { |u| u.first_name + " " + u.last_name }
# => { "user" : { "full_name" : "John Doe" } }
```

You can add the node only if a condition is true

```ruby
node(:email, if: -> { |u| u.valid_email? }) do |u|
	u.email
end
```

Nodes are evaluated at the rendering time, so you can use any instance variables or view helpers inside them

```ruby
node(:url) { |post| post_url(post) }
```

Custom nodes are really usefull to create flexible representations of your resources.

### Extends & Partials

Often objects have a basic representation that is shared accross different views and enriched according to it. To avoid code redundancy you can extend your template from any other RABL template.

```ruby
# app/views/users/base.json.rabl
attributes :id, :name

# app/views/users/private.json.rabl
extends 'users/base'
attributes :super_secret_attribute
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

### Caching

Caching is not a part of Rabl-rails. It is already in Rails itself, because caching all view output is the same as action caching (Rails caching is even better because it will also not run your queries).

Moreover caching each object in a collection can be really not effective with big collections or simple objects. This is also a nightmare with cache expiration.

### Render object directly

There are cases when you want to render object outside Rails view context. For instance to render objects in the console or to create message queue payloads. For these situations, you can use `RablRails.render` as show below:

```ruby
Rabl.render(object, template, :view_path => 'app/views', :format => :json) #=> "{...}"
```

You can find more informations about how to use this method in the [wiki](http://github.com/ccocchi/rabl-rails/wiki/Render-object-directly)

## Performance

Benchmarks have been made using this [application](http://github.com/ccocchi/rabl-benchmark), with rabl 0.6.14 and rabl-rails 0.1.0

Overall, Rabl-rails is **20% faster and use 10% less memory**.

You can see full tests on test application repository.

## Authors and contributors

* [Christopher Cocchi-Perrier](http://github.com/ccocchi) - Creator of the project

Want to add another format to Rabl-rails ? Checkout [JSON renderer](http://github.com/ccocchi/rabl-rails/blob/master/lib/rabl-rails/renderers/json.rb) for reference
Want to make another change ? Just fork and contribute, any help is very much appreciated

## Original idea

* [RABL](http://github.com/nesquena/rabl) Standart RABL gem. I used it a lot before deciding I wanted faster views

## Copyright

Copyright © 2011-2012 Christopher Cocchi-Perrier. See [MIT-LICENSE](http://github.com/ccocchi/rabl-rails/blob/master/MIT-LICENSE) for details.
