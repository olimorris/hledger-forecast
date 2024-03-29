lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hledger_forecast/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '~> 3.0'
  s.name        = 'hledger-forecast'
  s.version     = HledgerForecast::VERSION
  s.authors     = ['Oli Morris']
  s.summary     = "An extended wrapper around hledger's forecasting functionality"
  s.description = 'Use a CSV file for improved forecasting with hledger'
  s.email       = 'olimorris@users.noreply.github.com'
  s.homepage    = 'https://github.com/olimorris/hledger-forecast'
  s.license     = 'MIT'

  s.add_dependency "colorize", "~> 0.8.1"
  s.add_dependency "dentaku", "~> 3.5.1"
  s.add_dependency "highline", "~> 2.1.0"
  s.add_dependency "money", "~> 6.16.0"
  s.add_dependency "terminal-table", "~> 3.0.2"
  s.add_development_dependency 'rspec', '~> 3.12'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map do |f|
    File.basename(f)
  end
  s.require_paths = ['lib']
end
