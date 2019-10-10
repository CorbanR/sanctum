# frozen_string_literal: true

RSpec.describe Sanctum::Config do
  let(:helper) { SanctumTest::Helpers.new }

  context 'when config file is found' do
    after do
      helper.cleanup
    end

    it 'gets options' do
      helper.generate_test_file
      options = described_class.new(config_file: helper.test_file.path).options

      expect(options).to match(
        config_file: anything,
        sanctum: {
          color: true,
          force: false,
        },
        cli: {
          config_file: anything,
        },
        vault: {
          token: anything,
          addr: anything,
          secrets_version: 'auto',
          transit_key: anything,
        },
        sync: [
          { name: anything, prefix: anything, path: anything },
        ]
      )
    end

    it 'merges options correctly' do
      config_override = {
        sanctum: { color: false, force: true },
        vault: { token: 'foo', addr: 'bar', secrets_version: '1', transit_key: 'cool' },
        sync: [{ name: 'foo', prefix: 'bar', path: 'baz' }],
      }

      helper.generate_test_file(config_override)
      options = described_class.new(config_file: helper.test_file.path).options
      expect(options).to match(
        config_override.merge(
          config_file: anything,
          cli: {
            config_file: anything,
          }
        )
      )
    end
  end

  context 'when config file is not found' do
    it 'raises ConfigFileNotFound error' do
      expect { described_class.new.options }.to raise_error(Sanctum::Config::ConfigFileNotFound)
    end
  end

  context 'when sync targets are not defined' do
    after do
      helper.cleanup
    end

    it 'raises NoSyncTargetsDefined error' do
      helper.generate_test_file(sync: [])
      expect { described_class.new(config_file: helper.test_file.path).options }.to raise_error(Sanctum::Config::NoSyncTargetsDefined)
    end
  end

  context 'when invalid target[s] is specified' do
    after do
      helper.cleanup
    end

    it 'raises TargetsNotFound error' do
      helper.generate_test_file(sync: [{ name: 'foo' }, { name: 'bar' }, { name: 'baz' }])
      expect do
        described_class.new(config_file: helper.test_file.path, targets: %w[invalid1 invalid2 invalid3]).options
      end.to raise_error(Sanctum::Config::TargetsNotFound)
    end
  end
end
