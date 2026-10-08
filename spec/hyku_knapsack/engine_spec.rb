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

  describe 'translations' do
    # A knapsack locale file overriding a key Hyku's own locales also define (Hyku's beats Hyrax's).
    let(:key) { 'hyrax.homepage.featured_researcher.missing' }
    let(:locales) { described_class.root.join('config', 'locales') }
    let(:override) { locales.join('zz_engine_spec_override.en.yml') }
    let!(:created_locales) { !locales.exist? }

    before do
      FileUtils.mkdir_p(locales)
      File.write(override, { 'en' => key.split('.').reverse.inject('Knapsack wins') { |value, k| { k => value } } }.to_yaml)
    end

    after do
      FileUtils.rm_f(override)
      FileUtils.rmdir(locales) if created_locales
      I18n.load_path.delete(override.to_s)
      I18n.backend.reload!
    end

    it "win over a key Hyku's own locales define once boot reorders Hyku's" do
      files = [Rails.root.join('config', 'application.rb').to_s, described_class.root.join('lib', 'hyku_knapsack', 'engine.rb').to_s]
      ActiveSupport.instance_variable_get(:@load_hooks)[:after_initialize].map(&:first)
                   .select { |hook| files.include?(hook.source_location.first) }
                   .each { |hook| Rails.application.instance_exec(Rails.application, &hook) }

      expect(I18n.t(key)).to eq 'Knapsack wins'
    end

    it "still win after a development reload re-runs Hyku's to_prepare" do
      Rails.application.config.to_prepare_blocks.each(&:call)

      expect(I18n.t(key)).to eq 'Knapsack wins'
    end
  end
end
