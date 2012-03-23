require 'rake'

Gem::Specification.new do |s|
  s.name         = 'jedlik'
  s.version      = '0.0.1'
  s.summary      = "Communicate with Amazon DynamoDB."
  s.description  = "Communicate with Amazon DynamoDB. Raw access to the full API without having to handle temporary credentials or HTTP requests by yourself."
  s.author       = "Hashmal"
  s.email        = "jeremypinat@gmail.com"
  s.require_path = 'lib'
  s.files        = FileList['lib/**/*.rb', '[A-Z]*', 'spec/**/*'].to_a
  s.homepage     = 'http://github.com/hashmal/jedlik'

  s.add_development_dependency 'rspec'
  s.add_runtime_dependency 'typhoeus'
end
