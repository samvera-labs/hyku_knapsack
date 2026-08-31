# frozen_string_literal: true

require 'rails_helper'
require HykuKnapsack::Engine.root.join('lib/generators/hyku_knapsack/work_resource/work_resource_generator').to_s

RSpec.describe HykuKnapsack::WorkResourceGenerator do
  # The generator writes relative to '../', so the knapsack root is the parent
  # of its destination. Give it a throwaway pair of directories.
  let(:knapsack) { Dir.mktmpdir }
  let(:destination) { File.join(knapsack, 'hyrax-webapp') }
  let(:static_schema) { File.join(knapsack, 'config', 'metadata', 'thing.yaml') }

  after { FileUtils.remove_entry(knapsack) }

  def generate(action, name: 'Thing', args: [])
    generator = described_class.new([name], args, destination_root: destination)
    generator.shell.mute { generator.public_send(action) }
  end

  def written(path)
    File.read(File.join(knapsack, path))
  end

  describe 'the static schema' do
    it 'is written by default' do
      generate(:create_metadata_config)

      expect(File).to exist(static_schema)
    end

    it 'is skipped when generating for flexible metadata' do
      generate(:create_metadata_config, args: ['--flexible'])

      expect(File).not_to exist(static_schema)
    end
  end

  describe 'the model' do
    before { generate(:create_model) }

    it 'guards the schema includes at runtime rather than at generation' do
      expect(written('app/models/thing.rb')).to include 'if Hyrax.config.work_include_metadata?'
    end

    it 'includes the Hyku behavior the knapsack expects' do
      expect(written('app/models/thing.rb')).to include('include Hyrax::NestedWorks')
        .and include('prepend OrderAlready.for(:creator)')
    end

    it 'includes each module exactly once' do
      occurrences = written('app/models/thing.rb').scan('include Hyrax::ArResource').size

      expect(occurrences).to eq 1
    end

    it 'omits the lazy migration when there is no ActiveFedora counterpart' do
      expect(written('app/models/thing.rb')).not_to include 'ValkyrieLazyMigration'
    end
  end

  describe 'the model for a Resource that migrates from ActiveFedora' do
    it 'declares the lazy migration' do
      generate(:create_model, name: 'GenericWorkResource')

      expect(written('app/models/generic_work_resource.rb'))
        .to include 'Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork)'
    end
  end

  describe 'the form' do
    before { generate(:create_form) }

    it 'inherits from the Valkyrie resource form' do
      expect(written('app/forms/thing_form.rb')).to include 'class ThingForm < Hyrax::Forms::ResourceForm(Thing)'
    end

    it 'keeps the flexible metadata hook Hyrax generates' do
      expect(written('app/forms/thing_form.rb')).to include 'check_if_flexible(Thing)'
    end
  end

  describe 'the indexer' do
    before { generate(:create_indexer) }

    it 'inherits from the Valkyrie work indexer' do
      expect(written('app/indexers/thing_indexer.rb')).to include 'class ThingIndexer < Hyrax::ValkyrieWorkIndexer'
    end

    it 'includes Hyku indexing' do
      expect(written('app/indexers/thing_indexer.rb')).to include 'include HykuIndexing'
    end
  end
end
