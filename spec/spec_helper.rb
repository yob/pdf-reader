# coding: utf-8

require "rubygems"
require "bundler"
Bundler.setup

require 'pdf/reader'
require 'timeout'
require 'singleton'
require 'digest/md5'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f }

RSpec.configure do |config|
  config.expect_with :rspec, :stdlib
  config.include ReaderSpecHelper
end
