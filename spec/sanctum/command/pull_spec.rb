RSpec.describe Sanctum::Command::Pull do
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

    it "pulls secrets from vault and dumps to filesystem" do
      described_class.new(options).run
      file_exists = File.exist?("#{config_path}/#{options.dig(:sync).first.dig(:path)}/iad/prod/env")

      expect(file_exists).to be(true)
    end

    it "class returns updated targets with correct secrets_version" do
      expect(described_class.new(options).run).to eq(
        [
          {
            :name => "vault-test",
            :prefix => "vault-test",
            :path => "vault/vault-test",
            :secrets_version => "1",
            :transit_key => "transit/keys/vault-test",
          },
        ]
      )
    end

    it "outputs correct diff to stdout" do
      expect { described_class.new(options).run }.to output(
        /\.*+\/vault\/vault-test\/iad\/prod\/env => {"keyone"=>"#{random_value_one}", "keytwo"=>"#{random_value_two}"}/
      ).to_stdout
    end
  end

  context "kv version 1 secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "kv", secrets_version: 1)

      # Write secrets for testing
      helper.vault_command(vault_env,"vault write #{options.dig(:sync).first.dig(:prefix)}/iad/prod/env keyone=#{random_value_one} keytwo=#{random_value_two}")
    end

    it "pulls secrets from vault and dumps to filesystem" do
      described_class.new(options).run
      file_exists = File.exist?("#{config_path}/#{options.dig(:sync).first.dig(:path)}/iad/prod/env")
      expect(file_exists).to be(true)
    end

    it "class returns updated targets with correct secrets_version" do
      expect(described_class.new(options).run).to eq(
        [
          {
            :name => "vault-test",
            :prefix => "vault-test",
            :path => "vault/vault-test",
            :secrets_version => "1",
            :transit_key => "transit/keys/vault-test",
          },
        ]
      )
    end

    it "outputs correct diff to stdout" do
      expect { described_class.new(options).run }.to output(
        /\.*+\/vault\/vault-test\/iad\/prod\/env => {"keyone"=>"#{random_value_one}", "keytwo"=>"#{random_value_two}"}/
      ).to_stdout
    end

  end

  context "kv version 2 secrets backend" do
    before :each do
      helper.vault_cleanup
      helper.vault_setup(secrets_engine: "kv", secrets_version: 2)

      # Write secrets for testing
      vault_client.logical.write("#{options.dig(:sync).first.dig(:prefix)}/data/iad/prod/env", data: { keyone: "#{random_value_one}", keytwo: "#{random_value_two}" })
    end

    it "pulls secrets from vault and dumps to filesystem" do
      described_class.new(options).run
      file_exists = File.exist?("#{config_path}/#{options.dig(:sync).first.dig(:path)}/iad/prod/env")
      expect(file_exists).to be(true)
    end

    it "ignores secrets with nil value" do
      # Write secrets for testing
      vault_client.logical.write("#{options.dig(:sync).first.dig(:prefix)}/data/iad/edge/env", data: {gonna: "die"})
      # Then... delete it
      vault_client.request(:delete,"/v1/#{options.dig(:sync).first.dig(:prefix)}/data/iad/edge/env")
      run_stderr = with_captured_stderr { described_class.new(options).run }

      expect(run_stderr).to include("contains a null vaule")
    end

    it "class returns updated targets prefix with `data` and correct secrets_version" do
      expect(described_class.new(options).run).to eq(
        [
          {
            :name => "vault-test",
            :prefix => "vault-test/data",
            :path => "vault/vault-test",
            :secrets_version => "2",
            :transit_key => "transit/keys/vault-test",
          },
        ]
      )
    end

    it "outputs correct diff and path to stdout" do
      expect { described_class.new(options).run }.to output(
        /\.*+\/vault\/vault-test\/iad\/prod\/env => {"keyone"=>"#{random_value_one}", "keytwo"=>"#{random_value_two}"}/
      ).to_stdout
    end
  end
end
