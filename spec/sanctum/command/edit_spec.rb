RSpec.describe Sanctum::Command::Edit do
  let(:helper) {SanctumTest::Helpers.new}
  let(:options) { helper.options }
  let(:vault_client) { helper.vault_client }
  let(:vault_env) { helper.vault_env }
  let(:config_path) { "#{helper.config_path}/edit" }
  let(:args) {["#{config_path}/encrypted_file"]}
  let(:random_value_one) { ('a'..'z').to_a.shuffle[0,8].join }
  let(:random_value_two) { ('a'..'z').to_a.shuffle[0,8].join }

  before :each do
    helper.vault_cleanup
    helper.vault_setup

    # Create tmp folder
    FileUtils.mkdir_p(config_path)
    # Write transit encrypted data to local file to test edit command
    Sanctum::VaultTransit.write_to_file(vault_client, {args[0] => {"keyone" => "#{random_value_one}"}}, options[:sanctum][:transit_key])
  end

  it "edits an encrypted file" do
    described_class.new(options, args).run do |tmp_file|
      @original_contents = File.read(tmp_file.path)
      File.write(tmp_file.path, "newkey: #{random_value_two}")
    end

    encrypted_file = args[0]
    decrypted_contents = Sanctum::VaultTransit.decrypt(vault_client, {encrypted_file => File.read(encrypted_file)}, options[:sanctum][:transit_key])


    expect(File.file?(encrypted_file)).to be(true)
    expect(File.read(encrypted_file)).to include("vault")
    expect(YAML.load(@original_contents)).to eq({"keyone"=>"#{random_value_one}"})
    expect(decrypted_contents).to eq({encrypted_file => {"newkey" => "#{random_value_two}"}})
  end
end
