source 'http://rubygems.org'

gemspec

rails_version = ENV['RAILS_VERSION'] || 'default'

rails = case rails_version
when 'master'
  { github: 'rails/rails' }
when "default"
  '~> 4.2.0'
else
  "~> #{rails_version}"
end

minitest_version = rails_version == '4.0.0' ? '~> 4.7' : '~> 5.4'

gem 'activesupport', rails
gem 'railties', rails

group :test do
  gem 'minitest', minitest_version
  gem 'actionpack', rails

  if rails_version > '4.0.0'
    gem 'actionview', rails
  end
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
