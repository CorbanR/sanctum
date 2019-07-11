# frozen_string_literal: true

RSpec.describe Sanctum::GetConfig::ConfigMerge do
  let(:helper) { SanctumTest::Helpers.new }

  it 'gets correct default options' do
    default_options = described_class.new(config_file: '/tmp/sanctum.yaml', targets: nil, force: nil).default_options

    expect(default_options).to match(
      config_file: '/tmp/sanctum.yaml',
      sanctum: {
        color: true,
        force: false,
        secrets_version: 'auto',
        transit_key: nil,
      },
      vault: {
        token: nil,
        url: 'https://127.0.0.1:8200',
      }
    )
  end

  context 'when env vars are set' do
    it 'gets correct env options' do
      stub_const('ENV', 'VAULT_ADDR' => 'https://localhost:8200', 'VAULT_TOKEN' => 'asdf')
      env_options = described_class.new(config_file: nil, targets: nil, force: nil).env_options

      expect(env_options).to match(
        vault: {
          url: 'https://localhost:8200',
          token: 'asdf',
        }
      )
    end
  end

  context 'when env vars are not set' do
    it 'gets correct env options' do
      env_options = described_class.new(config_file: nil, targets: nil, force: nil).env_options

      expect(env_options).to match(vault: {})
    end
  end

  it 'gets correct cli options' do
    cli_options = described_class.new(config_file: nil, targets: 'test', force: false).cli_options

    expect(cli_options).to match(
      cli: {
        targets: ['test'],
        force: false,
      }
    )
  end

  it 'gets correct config options' do
    config_file = "#{Dir.mktmpdir}/sanctum.yaml"
    test_options =
      {
        config_file: config_file,
        sync: [
          {
            name: 'vault-test',
            prefix: 'vault-test',
            path: 'vault/vault-test',
          },
        ],
      }
    # Write test file to tmp path
    File.write(config_file, test_options.to_yaml) unless File.file?(config_file)
    config_options = described_class.new(config_file: config_file, targets: nil, force: nil).config_options

    expect(config_options).to match(test_options)
  end

  context 'when env vars are set' do
    it 'merges options correctly' do
      stub_const('ENV', 'VAULT_ADDR' => 'https://localhost:8200', 'VAULT_TOKEN' => 'asdf')
      config_file = "#{Dir.mktmpdir}/sanctum.yaml"
      test_options =
        {
          config_file: config_file,
          sanctum: {
            force: false,
            color: false,
            transit_key: 'transit/keys/vault-test',
            secrets_version: '2',
          },
          vault: {
            url: 'http://vault:8200',
            token: '514c55f0-c452-99e3-55e0-8301b770b92c',
          },
          sync: [
            {
              name: 'vault-test',
              prefix: 'vault-test',
              path: 'vault/vault-test',
            },
          ],
        }
      # Write test file to tmp path
      File.write(config_file, test_options.to_yaml) unless File.file?(config_file)
      final_options = described_class.new(config_file: config_file, targets: nil, force: nil).final_options

      expect(final_options).to match(
        config_file: config_file,
        sanctum: {
          color: false,
          force: false,
          transit_key: 'transit/keys/vault-test',
          secrets_version: '2',
        },
        vault: {
          token: 'asdf',
          url: 'https://localhost:8200',
        },
        sync: [
          {
            name: 'vault-test',
            prefix: 'vault-test',
            path: 'vault/vault-test',
          },
        ],
        cli: {
          targets: nil,
          force: nil,
        }
      )
    end
  end

  context 'when env vars are NOT set' do
    it 'merges options correctly' do
      config_file = "#{Dir.mktmpdir}/sanctum.yaml"
      test_options =
        {
          config_file: config_file,
          sanctum: {
            force: false,
            color: false,
            transit_key: 'transit/keys/vault-test',
          },
          vault: {
            url: 'http://vault:8200',
            token: '514c55f0-c452-99e3-55e0-8301b770b92c',
          },
          sync: [
            {
              name: 'vault-test',
              prefix: 'vault-test',
              path: 'vault/vault-test',
            },
          ],
        }
      # Write test file to tmp path
      File.write(config_file, test_options.to_yaml) unless File.file?(config_file)
      final_options = described_class.new(config_file: config_file, targets: nil, force: nil).final_options

      expect(final_options).to match(
        config_file: config_file,
        sanctum: {
          color: false,
          force: false,
          transit_key: 'transit/keys/vault-test',
          secrets_version: 'auto',
        },
        vault: {
          token: '514c55f0-c452-99e3-55e0-8301b770b92c',
          url: 'http://vault:8200',
        },
        sync: [
          {
            name: 'vault-test',
            prefix: 'vault-test',
            path: 'vault/vault-test',
          },
        ],
        cli: {
          targets: nil,
          force: nil,
        }
      )
    end
  end
end
