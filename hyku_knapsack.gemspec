# frozen_string_literal: true

require_relative "lib/hyku_knapsack/version"

Gem::Specification.new do |spec|
  spec.name        = "hyku_knapsack"
  spec.version     = HykuKnapsack::VERSION
  spec.authors     = ["Rob Kaufman"]
  spec.email       = ["rob@scientist.com"]
  spec.homepage    = "https://github.com/samvera-labs/hyku-knapsack"
  spec.summary     = "This gem provides a starting template for deploying Hyku, creating themes and adding overrides."
  spec.description = spec.summary
  spec.license     = "Apache-2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 5.2.0"
  spec.add_dependency "sentry-ruby"
  spec.add_dependency "sentry-rails"
  spec.add_dependency "sentry-sidekiq"
end
