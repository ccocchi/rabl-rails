source 'http://rubygems.org'

gemspec

rails_version = ENV['RAILS_VERSION'] || 'default'

rails = case rails_version
when 'master'
  { github: 'rails/rails' }
when "default"
  '~> 4.2.5'
else
  "~> #{rails_version}"
end

gem 'activesupport', rails
gem 'railties', rails

group :test do
  gem 'minitest', '~> 5.8'
  gem 'actionpack', rails
  gem 'actionview', rails
end

gem 'byebug'
gem 'benchmark-ips'
gem 'plist'

platforms :mri do
  gem 'libxml-ruby'
  gem 'oj'
end

platforms :jruby do
  gem 'nokogiri'
end
