# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HykuKnapsack::Engine do
  describe 'static assets' do
    let(:static_roots) do
      Rails.application.middleware
           .select { |middleware| middleware.name == 'ActionDispatch::Static' }
           .flat_map(&:args)
    end

    it 'serves the knapsack public directory' do
      expect(static_roots).to include described_class.root.join('public').to_s
    end
  end
end
