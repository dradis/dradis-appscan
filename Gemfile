source 'https://rubygems.org'

# Declare your gem's dependencies in dradis-appscan.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

if Dir.exists?('../dradis-plugins')
  gem 'dradis-plugins', path: '../dradis-plugins'
else
  gem 'dradis-plugins', github: 'dradis/dradis-plugins'
end
