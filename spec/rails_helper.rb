# frozen_string_literal: true

# Set environment variables BEFORE requiring Rails environment
# so initializers read the correct values on first load.
ENV["RAILS_ENV"] ||= "test"
# Use Hyku default (false) unless a spec or .env sets HYRAX_FLEXIBLE.
ENV['HYRAX_FLEXIBLE'] ||= 'false'
# Mirror the env setup from hyrax-webapp/spec/rails_helper.rb so Rails initializers
# (especially analytics and routing) behave correctly in test mode.
ENV['HYKU_ADMIN_HOST'] = 'test.host'
ENV['HYKU_ROOT_HOST'] = 'test.host'
ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = nil
ENV['HYKU_DEFAULT_HOST'] = nil
ENV['HYKU_MULTITENANT'] = 'true'
ENV['VALKYRIE_TRANSITION'] = 'true'
ENV['HYRAX_ANALYTICS_REPORTING'] = 'false'

# Boot Rails FIRST, before loading spec_helper.
# This ensures ENV is correctly set when Rails initializers run,
# and makes Rails.root available for spec_helper (which may load hyrax_with_valkyrie_helper).
require File.expand_path("../hyrax-webapp/config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "rspec/rails"
require "factory_bot_rails"
require 'capybara/rails'
require 'dry-validation'
require 'database_cleaner'

# Configure Hyrax to use Valkyrie-based models in tests (matches hyrax-webapp rails_helper).
Hyrax.config.admin_set_model = "AdminSetResource"
Hyrax.config.collection_model = "CollectionResource"

# Load factories from Hyrax's shared specs, hyrax-webapp, and this engine.
# This allows specs to use Hyrax shared examples (e.g. "a Hyrax::Work") and webapp factories.
FactoryBot.definition_file_paths = [
  Hyrax::Engine.root.join("lib/hyrax/specs/shared_specs/factories").to_s,
  File.expand_path("spec/factories", Rails.root),
  File.expand_path("spec/factories", HykuKnapsack::Engine.root)
]
FactoryBot.find_definitions

# Load knapsack-specific support files, then any support files the host app has added.
Dir[HykuKnapsack::Engine.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec', 'fixtures')]
  config.use_transactional_fixtures = false

  config.include HykuKnapsack::Engine.routes.url_helpers
  config.include Capybara::DSL
  config.include Fixtures::FixtureFileUpload if defined?(Fixtures::FixtureFileUpload)
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods
  config.include ApplicationHelper, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.include ActiveJob::TestHelper

  config.before do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end

# Appeasing the Hyrax user factory interface.
# In Hyku 7, RoleMapper#add may not exist; define it to delegate to Rolify.
def RoleMapper.add(user:, groups:)
  groups.each do |group|
    user.add_role(group.to_sym, Site.instance)
  end
end
