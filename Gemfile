source 'http://rubygems.org'

gemspec

rails_version = ENV['RAILS_VERSION'] || 'default'

rails = case rails_version
when 'master'
  {github: 'rails/rails'}
when "default"
  '~> 3.2.0'
else
  "~> #{rails_version}"
end

gem 'activesupport', rails
gem 'railties', rails

group :development, :test do
  gem 'actionpack', rails
end

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
