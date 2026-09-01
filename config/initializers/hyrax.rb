# frozen_string_literal: true

# Use this to override any Hyrax configuration from the Knapsack

# Needs to stay in #after_initialize
# @see https://github.com/notch8/palni_palci_knapsack/commit/e17e7e56
Rails.application.config.after_initialize do
  Hyrax.config do |config|
    config.flexible = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', 'false'))

    # Prepend to ensure knapsack profile is checked before the host app's profiles.
    config.schema_loader_config_search_paths.unshift(HykuKnapsack::Engine.root) \
      if config.respond_to?(:schema_loader_config_search_paths)
  end
end
