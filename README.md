# RABL for Rails #

RABL (Ruby API Builder Language) is a ruby templating system for rendering resources in different format (JSON, XML, BSON, ...). You can find documentation [here](http://github.com/nesquena/rabl).

RABL-rails only target Rails 3+ application because Rails 2 applications are becoming less and less present and will be obsolete with Rails 4. So let's look to the future !

So now you ask why used `rabl-rails` if `rabl` already exists and supports Rails. Rabl-rails is *faster* and uses * less memory* than standard rabl gem while letting you access same features. Of course, there are some slight changes to do on your templates to get this gem to work but it should't take you more than 5 minutes.

## Installation

Install as a gem :

```
gem install rabl-rails
```

or add directly to your `Gemfile`

```
gem 'rabl'
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

The fact of compiling the template outside of any rendering context prevent us to use any instances variables (with the exception of node) in the template because they are rendering objects. So instead, you'll have to use symbols of these variables. For example, to render the collection `@posts` inside your `PostController`, you need to use `:@posts` inside of the template.

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

## Usage