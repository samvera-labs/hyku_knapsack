# frozen_string_literal: true

# Work types this knapsack adds to the flexible metadata classes the host app
# sets in config/initializers/1flexible.rb, for example:
#
#   knapsack_additions = %w[
#     MyWorkResource
#   ]
knapsack_additions = %w[]

if knapsack_additions.any? &&
   ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', 'false'))
  # This file can run before the host app's 1flexible.rb, which is what
  # populates HYRAX_FLEXIBLE_CLASSES; load that first when it has not run yet.
  if ENV['HYRAX_FLEXIBLE_CLASSES'].to_s.empty?
    base = Rails.root.join('config', 'initializers', '1flexible.rb')
    load(base) if File.exist?(base)
  end

  existing = ENV.fetch('HYRAX_FLEXIBLE_CLASSES', '').split(',')
  ENV['HYRAX_FLEXIBLE_CLASSES'] = (existing + knapsack_additions).uniq.join(',')
end
