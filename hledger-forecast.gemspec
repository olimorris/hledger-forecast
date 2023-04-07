require 'hledger_forecast/version'

Gem::Specification.new do |s|
  s.name        = 'hledger-forecast'
  s.version     = HledgerForecast::VERSION
  s.authors     = ['Oli Morris']
  s.summary     = 'Utility to generate forecasts in Hledger'
  s.description = 'Uses a YAML file to generate monthly, quarterly, yearly and one-off transactions for better forecasting in Hledger'
  s.email       = 'olimorris@users.noreply.github.com'
  s.homepage    = 'https://github.com/olimorris/hledger-forecast'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency "highline", "~> 2.1.0"
  s.add_dependency "money", "~> 6.16.0"
  s.add_development_dependency 'rspec', '~> 3.12'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map do |f|
    File.basename(f)
  end
  s.require_paths = ['lib']
end
