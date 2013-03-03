source "http://rubygems.org"

gemspec

gem 'plist'

platforms :ruby do
  gem 'oj'
end

platforms :mri do
  gem 'libxml-ruby'
end

platforms :jruby do
  gem 'nokogiri'
end

group :test do
  gem 'rspec-mocks'
end
