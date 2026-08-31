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

  def generate(args)
    generator = described_class.new(['Thing'], args, destination_root: destination)
    generator.shell.mute { generator.create_metadata_config }
  end

  it 'writes the static schema by default' do
    generate([])

    expect(File).to exist(static_schema)
  end

  it 'skips the static schema when generating for flexible metadata' do
    generate(['--flexible'])

    expect(File).not_to exist(static_schema)
  end
end
