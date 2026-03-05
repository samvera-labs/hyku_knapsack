# frozen_string_literal: true

# Use this to override any Hyrax configuration from the Knapsack

Rails.application.config.after_initialize do
  Hyrax.config do |config|
    config.flexible = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', 'false'))

    # Prepend to ensure knapsack profile is checked before the host app's profiles.
    if config.respond_to?(:schema_loader_config_search_paths)
      paths = config.schema_loader_config_search_paths
      config.schema_loader_config_search_paths = [HykuKnapsack::Engine.root] + Array(paths)
    end
  end
end
