# frozen_string_literal: true

# Respect Hyku's default: HYRAX_FLEXIBLE is off unless set by the app (e.g. .env, docker-compose).
# Do not set ENV['HYRAX_FLEXIBLE'] here so downstream apps control it.

require "hyku_knapsack/version"
require "hyku_knapsack/engine"

# Disable include_metadata only when flexible mode is explicitly enabled.
ENV['HYRAX_DISABLE_INCLUDE_METADATA'] = 'true' if ENV.fetch('HYRAX_FLEXIBLE', 'false') == 'true'

module HykuKnapsack
  # Your code goes here...
end
