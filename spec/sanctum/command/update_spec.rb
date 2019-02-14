RSpec.describe Sanctum::Command::Update do
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

      # Write secrets for testing
      helper.vault_command(vault_env,"vault write #{options.dig(:sync).first.dig(:prefix)}/iad/prod/env keyone=#{random_value_one} keytwo=#{random_value_two}")
    end

    it "updates secrets engine" do
      mount_info_before_upgrade = vault_client.request(:get, "/v1/sys/internal/ui/mounts")
      described_class.new(options).run
      mount_info_after_upgrade = vault_client.request(:get, "/v1/sys/internal/ui/mounts")

      expect(mount_info_before_upgrade.dig(:data, :secret, "#{options.dig(:sync).first.dig(:prefix)}/".to_sym, :options, :version)).to be_nil
      expect(mount_info_after_upgrade.dig(:data, :secret, "#{options.dig(:sync).first.dig(:prefix)}/".to_sym, :options, :version)).to eq("2")
    end
  end

  context "kv version 1 secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "kv", secrets_version: 1)

      # Write secrets for testing
      helper.vault_command(vault_env,"vault write #{options.dig(:sync).first.dig(:prefix)}/iad/prod/env keyone=#{random_value_one} keytwo=#{random_value_two}")
    end

    it "updates secrets engine" do
      mount_info_before_upgrade = vault_client.request(:get, "/v1/sys/internal/ui/mounts")
      described_class.new(options).run
      mount_info_after_upgrade = vault_client.request(:get, "/v1/sys/internal/ui/mounts")

      expect(mount_info_before_upgrade.dig(:data, :secret, "#{options.dig(:sync).first.dig(:prefix)}/".to_sym, :options, :version)).to eq("1")
      expect(mount_info_after_upgrade.dig(:data, :secret, "#{options.dig(:sync).first.dig(:prefix)}/".to_sym, :options, :version)).to eq("2")
    end
  end

  context "kv version 2 secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "kv", secrets_version: 2)

      # Write secrets for testing
      vault_client.logical.write("#{options.dig(:sync).first.dig(:prefix)}/data/iad/prod/env", data: { keyone: "#{random_value_one}", keytwo: "#{random_value_two}" })
    end

    it "returns error message if mount is already kv version 2" do
      custom_helper = SanctumTest::Helpers.new(override_options: { cli: { force: false } })
      expect { described_class.new(custom_helper.options).run }.to raise_error(RuntimeError, /Mount appears to have already been updated/)
    end
  end
end
