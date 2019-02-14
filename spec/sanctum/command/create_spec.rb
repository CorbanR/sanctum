RSpec.describe Sanctum::Command::Create do
  let(:helper) { SanctumTest::Helpers.new }
  let(:options) { helper.options }
  let(:vault_client) { helper.vault_client }
  let(:config_path) { helper.config_path }
  let(:args) {["#{config_path}/encrypted_file"]}
  let(:random_value_one) { ('a'..'z').to_a.shuffle[0,8].join }

  before :each do
    helper.vault_cleanup
    helper.vault_setup

    # Create tmp folder
    FileUtils.mkdir_p("#{config_path}")
  end

  it "creates an encrypted file" do
    described_class.new(options, args).run do |tmp_file|
      File.write(tmp_file.path, "keyone: #{random_value_one}")
    end

    encrypted_file = args[0]
    decrypted_contents = Sanctum::VaultTransit.decrypt(vault_client, {encrypted_file => File.read(encrypted_file)}, options[:vault][:transit_key])


    expect(File.file?(encrypted_file)).to be(true)
    expect(File.read(encrypted_file)).to include("vault")
    expect(decrypted_contents).to eq({encrypted_file => {"keyone" => "#{random_value_one}"}})
  end
end
