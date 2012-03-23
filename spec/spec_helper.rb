require 'rspec'

$:.unshift (File.join (File.dirname __FILE__), 'lib')
require 'jedlik'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
