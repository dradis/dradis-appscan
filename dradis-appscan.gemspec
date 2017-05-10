$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dradis/plugins/appscan/version"
version = Dradis::Plugins::Appscan::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "dradis-appscan"
  s.version     = version
  s.authors     = ["Xavi Vila"]
  s.email       = ["xavi@securityroots.com"]
  s.homepage    = "http://dradisframework.org"
  s.summary     = "IBM Appscan Source upload add-on for Dradis Framework."
  s.description = "This add-on allows you to upload and parse reports from Appscan."
  s.license     = "GPL-2"

  s.files = `git ls-files`.split($\)

  s.add_dependency 'dradis-plugins', '~> 3.6'
  s.add_dependency 'nokogiri'
  s.add_dependency 'rake', '~> 12.0'

  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_dependency 'combustion', '~> 0.6.0'
  s.add_dependency 'rspec-rails'
end
