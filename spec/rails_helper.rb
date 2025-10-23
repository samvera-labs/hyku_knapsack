# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
ENV['HYRAX_FLEXIBLE'] ||= 'false'
# require File.expand_path('../config/environment', __dir__)
require File.expand_path("../hyrax-webapp/config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "factory_bot_rails"
FactoryBot.definition_file_paths = [File.expand_path("spec/factories", HykuKnapsack::Engine.root)]
FactoryBot.find_definitions

require 'capybara/rails'
require 'dry-validation'
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Require supporting ruby files from spec/support/ and subdirectories.  Note: engine, not Rails.root context.
Dir[HykuKnapsack::Engine.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = Rails.root.join('spec', 'fixtures')

  # They enable url_helpers not to throw error in Rspec system spec and request spec.
  # config.include Rails.application.routes.url_helpers
  # TODO is this needed?
  config.include HykuKnapsack::Engine.routes.url_helpers
  config.include Capybara::DSL
  # config.include Fixtures::FixtureFileUpload  # Commented out - not available in this context

  # Fix knapsack view path configuration for test environment
  # This ensures that knapsack views are prioritized over hyrax-webapp views
  # when running view specs in the test environment
  config.before(:each, type: :view) do
    # Simple approach: add knapsack view path to the view object
    view.view_paths.unshift(HykuKnapsack::Engine.root.join('app', 'views'))
  end
end
