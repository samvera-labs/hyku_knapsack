# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HykuKnapsack::ReseedValidChildConcerns do
  # Work models that carry the Hyrax::NestedWorks `valid_child_concerns` class
  # attribute. Derived from the registered concerns so this passes for whatever
  # work types the host app registers.
  let(:work_types) do
    Hyrax.config.curation_concerns.select { |klass| klass.respond_to?(:valid_child_concerns=) }
  end
  let(:expected) { Hyrax.config.curation_concerns.map(&:to_s) }

  # Restore whatever the app booted with, so mutating the class attribute in an
  # example cannot leak into others.
  around do |example|
    saved = work_types.index_with(&:valid_child_concerns)
    example.run
    saved.each { |klass, value| klass.valid_child_concerns = value }
  end

  describe '.call' do
    it 'reflects the fully-registered curation concerns on every work model' do
      # Simulate a stale snapshot: an empty child list, as an eager-load boot
      # can leave it when classes load before deferred concern registration.
      work_types.each { |klass| klass.valid_child_concerns = [] }

      described_class.call

      work_types.each do |klass|
        expect(klass.valid_child_concerns.map(&:to_s)).to match_array(expected)
      end
    end

    it 'excludes a type that bars itself via valid_child_concern?' do
      barred = work_types.first
      allow(barred).to receive(:valid_child_concern?).and_return(false)

      described_class.call

      work_types.each do |klass|
        expect(klass.valid_child_concerns).not_to include(barred)
      end
    end

    it 'keeps types that do not define valid_child_concern? as valid children' do
      described_class.call

      work_types.each do |klass|
        expect(klass.valid_child_concerns.map(&:to_s)).to match_array(expected)
      end
    end
  end
end
