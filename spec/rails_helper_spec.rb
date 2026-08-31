# frozen_string_literal: true

require 'rails_helper'

# Guards the harness contract that every downstream knapsack had to rediscover:
# Rails is booted before spec_helper, the Valkyrie models are configured, and
# factories resolve from all three layers.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'the knapsack spec harness' do
  it 'boots in the test environment' do
    expect(Rails.env).to eq 'test'
  end

  it 'boots the host application' do
    expect(Rails.application).to be_a Hyku::Application
  end

  it 'points Hyrax at the Valkyrie admin set model' do
    expect(Hyrax.config.admin_set_model).to eq 'AdminSetResource'
  end

  it 'points Hyrax at the Valkyrie collection model' do
    expect(Hyrax.config.collection_model).to eq 'CollectionResource'
  end

  it 'looks for factories in Hyrax, the host application and the engine' do
    expect(FactoryBot.definition_file_paths).to eq [
      Hyrax::Engine.root.join('lib/hyrax/specs/shared_specs/factories').to_s,
      File.expand_path('spec/factories', Rails.root),
      File.expand_path('spec/factories', HykuKnapsack::Engine.root)
    ]
  end

  it 'registers the factories the host application defines' do
    expect { FactoryBot::Internal.factory_by_name(:user) }.not_to raise_error
  end

  it 'resolves the class that Hyrax\'s work factory names' do
    expect(FactoryBot::Internal.factory_by_name(:hyrax_work).build_class).to eq Hyrax::Test::SimpleWork
  end

  it 'loads the support files the host application defines' do
    expect(self).to respond_to :be_cname
  end

  it 'defines the RoleMapper.add that the Hyrax user factory calls' do
    expect(RoleMapper.method(:add).parameters).to eq [%i[keyreq user], %i[keyreq groups]]
  end

  it 'exposes the fixture file helpers to examples' do
    expect(fixture_file_path('nothing.txt').to_s).to eq Rails.root.join('spec', 'fixtures', 'nothing.txt').to_s
  end
end
# rubocop:enable RSpec/DescribeClass
