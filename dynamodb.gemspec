require "./lib/dynamodb/version"

Gem::Specification.new do |s|
  s.name         = 'dynamodb'
  s.version      = DynamoDB::VERSION
  s.summary      = "Communicate with Amazon DynamoDB."
  s.description  = "Communicate with Amazon DynamoDB. Raw access to the full API without having to handle temporary credentials or HTTP requests by yourself."
  s.authors      = ["Brandon Keene", "Dave Yeu"]
  s.email        = ["bkeene@gmail.com", "dave@groupme.com"]
  s.require_path = 'lib'
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage     = 'http://github.com/groupme/dynamodb'

  s.add_runtime_dependency 'multi_json', '>= 1.3.7'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '3.11.0'
  s.add_development_dependency 'webmock', '3.11.2'
end

