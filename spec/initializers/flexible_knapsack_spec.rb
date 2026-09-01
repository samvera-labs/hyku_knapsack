# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'config/initializers/2flexible_knapsack.rb' do
  let(:initializer) { HykuKnapsack::Engine.root.join('config', 'initializers', '2flexible_knapsack.rb') }

  around do |example|
    flexible_classes = ENV.fetch('HYRAX_FLEXIBLE_CLASSES', nil)
    example.run
    ENV['HYRAX_FLEXIBLE_CLASSES'] = flexible_classes
  end

  it 'leaves the host app flexible classes alone while the knapsack adds none' do
    ENV['HYRAX_FLEXIBLE_CLASSES'] = 'AdminSetResource,CollectionResource'

    expect { load initializer }.not_to(change { ENV.fetch('HYRAX_FLEXIBLE_CLASSES', nil) })
  end
end
# rubocop:enable RSpec/DescribeClass
