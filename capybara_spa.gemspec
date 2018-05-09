
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "capybara_spa/version"

Gem::Specification.new do |spec|
  spec.name          = "capybara_spa"
  spec.version       = CapybaraSpa::VERSION
  spec.authors       = ["Zach Dennis"]
  spec.email         = ["zach.dennis@gmail.com"]

  spec.summary       = %q{A friendly library for Capybara to make running single page application servers easy}
  spec.description   = %q{A friendly library for Capybara to make running single page application servers easy as pie for integration, e2e, and feature level specs.}
  spec.homepage      = "https://github.com/mhs/capybara-spa"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "capybara", "~> 3.0"
  spec.add_development_dependency "bump", "~> 0.6.0"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "chromedriver-helper", "~> 1.2"
  spec.add_development_dependency "pry-byebug", "~> 3.6"
  spec.add_development_dependency "selenium-webdriver", "~> 3.11"
  spec.add_development_dependency "simplecov", "~> 0.16"
end
