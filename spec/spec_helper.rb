require 'rspec'

$:.unshift(File.join(File.dirname __FILE__), 'lib')
require 'jedlik'
require 'webmock/rspec'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
