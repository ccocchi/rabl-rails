# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'active_support/test_case'
require 'rabl-fast-json'
