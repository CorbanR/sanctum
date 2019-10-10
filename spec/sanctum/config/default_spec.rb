# frozen_string_literal: true

RSpec.describe Sanctum::Config::Default do
  context 'when env vars are not set' do
    it 'gets default options' do
      options = described_class.new.options

      expect(options).to match(
        sanctum: {
          color: true,
          force: false,
        },
        cli: {},
        vault: {
          addr: 'http://127.0.0.1:8200',
          secrets_version: 'auto',
        },
        sync: []
      )
    end
  end

  context 'when env vars are set' do
    it 'gets correct options' do
      stub_const('ENV', 'VAULT_ADDR' => 'https://localhost:8200', 'VAULT_TOKEN' => 'asdf')
      options = described_class.new.options

      expect(options).to match(
        sanctum: {
          color: true,
          force: false,
        },
        cli: {},
        vault: {
          addr: 'https://localhost:8200',
          secrets_version: 'auto',
          token: 'asdf',
        },
        sync: []
      )
    end
  end

  it 'gets correct cli options' do
    options = described_class.new(config_file: '/path/to/config', targets: ['test'], force: false).options

    expect(options[:cli]).to match(
      config_file: '/path/to/config',
      targets: ['test'],
      force: false
    )
  end

  it 'finds sanctum.yaml' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.touch('sanctum.yaml')
        options = described_class.new.options

        expect(options[:config_file]).to match("#{dir}/sanctum.yaml")
      end
    end
  end
end
