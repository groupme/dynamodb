Gem::Specification.new do |s|
  s.name         = 'jedlik'
  s.version      = '0.0.2'
  s.summary      = "Communicate with Amazon DynamoDB."
  s.description  = "Communicate with Amazon DynamoDB. Raw access to the full API without having to handle temporary credentials or HTTP requests by yourself."
  s.authors      = ["Hashmal", "Brandon Keene"]
  s.email        = ["jeremypinat@gmail.com", "bkeene@gmail.com"]
  s.require_path = 'lib'
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage     = 'http://github.com/hashmal/jedlik'

  s.add_runtime_dependency 'typhoeus'
  s.add_runtime_dependency 'yajl-ruby'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
end
