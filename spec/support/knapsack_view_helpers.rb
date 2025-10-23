# frozen_string_literal: true

# This shared context ensures that view specs in the knapsack correctly
# prioritize knapsack views over hyrax-webapp views.
#
# Usage:
#   RSpec.describe 'path/to/view.html.erb', type: :view do
#     include_context 'with knapsack view paths'
#     # ... your spec code
#   end
#
RSpec.shared_context 'with knapsack view paths' do
  before do
    # Prepend the knapsack view paths so that views in the knapsack
    # take precedence over views in hyrax-webapp.
    # This mimics what happens in production via the Engine's after_initialize hook.
    view.view_paths.unshift(HykuKnapsack::Engine.root.join('app', 'views'))
  end
end

# Automatically include this context for all view specs in the knapsack
RSpec.configure do |config|
  config.include_context 'with knapsack view paths', type: :view
end
