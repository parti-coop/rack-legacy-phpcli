# coding: utf-8
# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "rack-legacy-phpcli"
  spec.version       = '0.0.1'
  spec.authors       = ["dali"]
  spec.email         = ["dali@ufofactory.org"]

  spec.summary       = %q{rake module with php-cli}
  spec.description   = %q{rake module with php-cli}
  spec.homepage      = "http://ufofactory.org"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://gem.ufofactory.org'
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  #spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "httparty"
  spec.add_development_dependency "nokogiri", "~> 1.8.1"
  spec.add_development_dependency "mechanize", '~> 2.0'

  spec.add_dependency 'rack', '~> 1.6'
  spec.add_dependency 'childprocess'
  spec.add_dependency 'rack-legacy', '~> 1.0'
end
