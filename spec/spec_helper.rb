# frozen_string_literal: true

# Delegate to hyrax-webapp for the full Rails environment
# The knapsack engine will be loaded automatically by the Rails environment
require File.expand_path("../hyrax-webapp/spec/rails_helper.rb", __dir__)
require File.expand_path("../hyrax-webapp/spec/spec_helper.rb", __dir__)
