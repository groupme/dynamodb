require 'rspec'

$:.unshift(File.join(File.dirname __FILE__), 'lib')
require 'dynamodb'
require 'webmock/rspec'

RSpec.configure do |config|
end
