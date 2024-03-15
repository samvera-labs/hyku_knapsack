# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0 to add schemas that are located in config/metadata/*.yaml

module Hyrax
  module SimpleSchemaLoaderDecorator
    def config_search_paths
      super + [HykuKnapsack::Engine.root]
    end
  end
end

Hyrax::SimpleSchemaLoader.prepend(Hyrax::SimpleSchemaLoaderDecorator)
