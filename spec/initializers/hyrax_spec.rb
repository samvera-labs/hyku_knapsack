# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'config/initializers/hyrax.rb' do
  it 'leaves the host application work type first in the curation concerns' do
    expect(Hyrax.config.registered_curation_concern_types.first).to eq 'GenericWork'
  end
end
