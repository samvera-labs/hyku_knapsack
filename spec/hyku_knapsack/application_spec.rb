# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyku::Application do
  let(:rails_root) { Rails.root }
  let(:hyku_knapsack_root) { HykuKnapsack::Engine.root }

  describe '.theme_view_path_roots' do
    it 'includes the Rails root and the Hyku Knapsack root' do
      expect(described_class.theme_view_path_roots).to eq([rails_root.to_s, hyku_knapsack_root.to_s])
    end
  end

  describe '.path_for' do
    context 'when relative path does not exist in the knapsack' do
      it 'returns the fall back path' do
        expect(described_class.path_for('foo')).to eq(rails_root.join('foo').to_s)
      end
    end

    context 'when relative path exists in the knapsack' do
      it 'returns the relative path' do
        path = 'app/models/hyku_knapsack/application_record.rb'
        expect(described_class.path_for(path)).to eq(hyku_knapsack_root.join(path).to_s)
      end
    end
  end
end
