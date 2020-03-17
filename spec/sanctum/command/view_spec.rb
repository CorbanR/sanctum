# frozen_string_literal: true

RSpec.describe Sanctum::Command::View do
  let(:helper) { SanctumTest::Helpers.new }
  let(:options) { helper.options }
  let(:vault_client) { helper.vault_client }
  let(:config_path) { helper.config_path }
  let(:args) { ["#{config_path}/encrypted_file"] }
  let(:random_value_one) { ('a'..'z').to_a.sample(8).join }

  before do
    # Write transit encrypted data to local file to test view command
    Sanctum::Adapter::Vault::Transit.write_to_file(vault_client, { args[0] => { 'keyone' => random_value_one.to_s } }, options[:sanctum][:transit_key])
  end

  # TODO: This could probably be better
  it 'views an encrypted file' do
    expect { described_class.new(options, args).run(command = nil) }.to output(%r{keyone: #{random_value_one}}).to_stdout
  end
end
