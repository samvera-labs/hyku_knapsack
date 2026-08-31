# frozen_string_literal: true

# Set environment variables BEFORE requiring the Rails environment so that
# initializers read the correct values on their first and only load.
ENV["RAILS_ENV"] ||= "test"
# Knapsacks that run flexible metadata set HYRAX_FLEXIBLE in their own .env.
ENV['HYRAX_FLEXIBLE'] ||= 'false'
# Mirrors hyrax-webapp/spec/rails_helper.rb, which this file replaces.
ENV['HYKU_ADMIN_HOST'] = 'test.host'
ENV['HYKU_ROOT_HOST'] = 'test.host'
ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = nil
ENV['HYKU_DEFAULT_HOST'] = nil
ENV['HYKU_MULTITENANT'] = 'true'
ENV['VALKYRIE_TRANSITION'] = 'true'
ENV['HYRAX_ANALYTICS_REPORTING'] = 'false'

# Boot Rails before spec_helper: hyrax-webapp's spec_helper resolves
# hyrax_with_valkyrie_helper relative to Rails.root.
require File.expand_path("../hyrax-webapp/config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "rspec/rails"
require "factory_bot_rails"
require 'capybara/rails'
require 'dry-validation'
require 'database_cleaner'

Hyrax.config.admin_set_model = "AdminSetResource"
Hyrax.config.collection_model = "CollectionResource"

# Hyrax's :hyrax_work factory declares `class: 'Hyrax::Test::SimpleWork'`, and
# FactoryBot constantizes that when it compiles the parent chain. Requiring
# Hyrax's shared_specs/simple_work.rb, as hyrax-webapp's own rails_helper does,
# would also define an ActiveFedora SimpleWorkLegacy, run the Wings and lazy
# migration registration, and include the core/basic/monograph schemas. Define
# only the constant the factory needs.
module Hyrax
  module Test
    class SimpleWork < Hyrax::Work; end unless const_defined?(:SimpleWork)
  end
end

# Hyrax's shared specs first, then hyrax-webapp, then this engine, so each layer
# can extend the factories the layer below it defines.
FactoryBot.definition_file_paths = [
  Hyrax::Engine.root.join("lib/hyrax/specs/shared_specs/factories").to_s,
  File.expand_path("spec/factories", Rails.root),
  File.expand_path("spec/factories", HykuKnapsack::Engine.root)
]
FactoryBot.find_definitions

# Appeasing the Hyrax user factory interface.
def RoleMapper.add(user:, groups:)
  groups.each do |group|
    user.add_role(group.to_sym, Site.instance)
  end
end

# hyrax-webapp's support files first (multitenancy metadata hooks, matchers,
# shared examples), then the knapsack's, so a knapsack file can override.
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
Dir[HykuKnapsack::Engine.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec', 'fixtures')]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!

  config.include HykuKnapsack::Engine.routes.url_helpers
  config.include Capybara::DSL
  config.include Fixtures::FixtureFileUpload
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
