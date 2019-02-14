RSpec.describe Sanctum::Command::Check do
  let(:helper) {SanctumTest::Helpers.new}
  let(:options) { helper.options }
  let(:vault_client) { helper.vault_client }
  let(:vault_env) { helper.vault_env }
  let(:config_path) { helper.config_path }
  let(:random_value_one) { ('a'..'z').to_a.shuffle[0,8].join }
  let(:random_value_two) { ('a'..'z').to_a.shuffle[0,8].join }

  context "generic secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "generic")

      # Write transit encrypted data to local file to test check command
      Sanctum::VaultTransit.write_to_file(vault_client, {"#{config_path}/#{options.dig(:sync).first.dig(:path)}/iad/dev/env" => {"keyone" => "#{random_value_one}"}}, options[:vault][:transit_key])
      # Write secrets to vault for testing check command
      helper.vault_command(vault_env,"vault write #{options.dig(:sync).first.dig(:prefix)}/iad/prod/env keyone=#{random_value_one} keytwo=#{random_value_two}")
    end

    # TODO This could probably be better
    it "checks differences between local files and vault" do
      expect { described_class.new(options).run }.to output(
        /\.*+\/vault\/vault-test\/iad\/prod\/env => {"keyone"=>"#{random_value_one}", "keytwo"=>"#{random_value_two}"}/
      ).to_stdout
    end
  end

  context "kv version 1 secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "kv", secrets_version: 1)

      # Write transit encrypted data to local file to test check command
      Sanctum::VaultTransit.write_to_file(vault_client, {"#{config_path}/#{options.dig(:sync).first.dig(:path)}/iad/dev/env" => {"keyone" => "#{random_value_one}"}}, options[:vault][:transit_key])
      # Write secrets to vault for testing check command
      helper.vault_command(vault_env,"vault write #{options.dig(:sync).first.dig(:prefix)}/iad/prod/env keyone=#{random_value_one} keytwo=#{random_value_two}")
    end

    # TODO This could probably be better
    it "checks differences between local files and vault" do
      expect { described_class.new(options).run }.to output(
        /\.*+\/vault\/vault-test\/iad\/prod\/env => {"keyone"=>"#{random_value_one}", "keytwo"=>"#{random_value_two}"}/
      ).to_stdout
    end
  end

  context "kv version 2 secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "kv", secrets_version: 2)

      # Write transit encrypted data to local file to test check command
      Sanctum::VaultTransit.write_to_file(vault_client, {"#{config_path}/#{options.dig(:sync).first.dig(:path)}/data/iad/dev/env" => {"keyone" => "#{random_value_one}"}}, options[:vault][:transit_key])
      # Write secrets to vault for testing check command
      vault_client.logical.write("#{options.dig(:sync).first.dig(:prefix)}/data/iad/prod/env", data: { keyone: "#{random_value_one}", keytwo: "#{random_value_two}" })
    end

    # TODO This could probably be better
    it "checks differences between local files and vault" do
      expect { described_class.new(options).run }.to output(
        /\.*+\/vault\/vault-test\/data\/iad\/prod\/env => {"keyone"=>"#{random_value_one}", "keytwo"=>"#{random_value_two}"}/
      ).to_stdout
    end
  end
end
