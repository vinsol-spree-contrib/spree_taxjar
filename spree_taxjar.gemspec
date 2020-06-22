# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_taxjar'
  s.version     = '4.1'
  s.summary     = 'Spree extension to calculate sales tax in states of USA'
  s.description = 'Spree extension for providing TaxJar services in USA'
  s.required_ruby_version = '>= 2.5.0'

  s.author    = ['Nimish Gupta', 'Tanmay Sinha']
  s.email     = ['nimish.gupta@vinsol.com', 'tanmay@vinsol.com']
  s.license = 'BSD-3'

  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 4.1'

  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'taxjar-ruby', '~> 3.0'

  s.add_development_dependency 'capybara', '~> 3.32'
  s.add_development_dependency 'coffee-rails', '~> 5.0'
  s.add_development_dependency 'database_cleaner', '~> 1.8.5'
  s.add_development_dependency 'factory_bot', '~> 5.2'
  s.add_development_dependency 'ffaker', '~> 2.15'
  s.add_development_dependency 'rspec-rails', '~> 4.0', '>= 4.0.1'
  s.add_development_dependency 'sass-rails', '~> 6.0'
  s.add_development_dependency 'selenium-webdriver', '~> 3.142', '>= 3.142.7'
  s.add_development_dependency 'simplecov', '~> 0.18.5'
  s.add_development_dependency 'sqlite3', '~> 1.4'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'appraisal'
end
