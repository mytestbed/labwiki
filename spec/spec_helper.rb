require 'simplecov'
# Generate coverage
SimpleCov.start { add_filter "/(spec|vendor)/" }

# Setup MiniTest
gem 'minitest'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/spec'

require 'capybara'
require 'capybara_minitest_spec'

Capybara.app = eval("Rack::Builder.new {( #{File.read(File.dirname(__FILE__) + '/../standard_rack_config.ru')}\n)}")
Capybara.javascript_driver = :webkit
#Capybara.default_driver = :selenium
