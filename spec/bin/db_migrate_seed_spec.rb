# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'bin/db-migrate-seed.sh' do
  let(:env) do
    { 'HYRAX_SKIP_WINGS' => nil, 'DB_HOST' => 'db', 'DB_PORT' => '5432',
      'SOLR_HOST' => 'solr', 'SOLR_PORT' => '8983',
      'FCREPO_HOST' => 'fcrepo', 'FCREPO_PORT' => '8080' }
  end

  def stub_bin(dir, record)
    FileUtils.cp(HykuKnapsack::Engine.root.join('bin', 'db-migrate-seed.sh'), dir)
    File.write(File.join(dir, 'service-wait.sh'), "#!/bin/sh\necho \"$1\" >> \"#{record}\"\n")
    FileUtils.chmod(0o755, Dir.glob(File.join(dir, '*.sh')))
    File.write(File.join(dir, 'Gemfile'), "# no gems\n")
  end

  def service_waits(overrides = {})
    Dir.mktmpdir do |dir|
      record = File.join(dir, 'waited')
      stub_bin(dir, record)
      script = File.join(dir, 'db-migrate-seed.sh')
      ran = Bundler.with_unbundled_env { system(env.merge(overrides), script, chdir: dir) }

      expect(ran).to be true
      File.exist?(record) ? File.read(record).split("\n") : []
    end
  end

  it 'waits for Fedora when Wings is enabled' do
    expect(service_waits).to eq ['db:5432', 'fcrepo:8080', 'solr:8983']
  end

  it 'skips Fedora when HYRAX_SKIP_WINGS is set' do
    expect(service_waits('HYRAX_SKIP_WINGS' => 'true')).to eq ['db:5432', 'solr:8983']
  end

  it 'casts HYRAX_SKIP_WINGS the way Hyrax.config.disable_wings does' do
    expect(service_waits('HYRAX_SKIP_WINGS' => '1')).to eq ['db:5432', 'solr:8983']
  end

  it 'skips Fedora when FCREPO_HOST is the no-Fedora sentinel' do
    expect(service_waits('FCREPO_HOST' => 'NO_FCREPO_HOST_DEFINED')).to eq ['db:5432', 'solr:8983']
  end

  it 'skips Fedora when FCREPO_HOST is unset' do
    expect(service_waits('FCREPO_HOST' => nil)).to eq ['db:5432', 'solr:8983']
  end
end
# rubocop:enable RSpec/DescribeClass
