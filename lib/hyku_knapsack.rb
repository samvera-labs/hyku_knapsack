# frozen_string_literal: true

# Enable if this project uses flexible metadata (Hyku 7). Set before the engine is required
# so initializers and Hyrax read the correct value.
# ENV['HYRAX_FLEXIBLE'] = 'true'

# Disable include_metadata when flexible mode is enabled.
ENV['HYRAX_DISABLE_INCLUDE_METADATA'] = 'true' if ENV.fetch('HYRAX_FLEXIBLE', 'true') == 'true'

require "hyku_knapsack/version"
require "hyku_knapsack/engine"

module HykuKnapsack
  # Your code goes here...
end
