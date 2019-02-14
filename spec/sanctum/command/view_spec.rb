RSpec.describe Sanctum::Command::View do
  let(:helper) {SanctumTest::Helpers.new}
  let(:options) { helper.options }
  let(:vault_client) { helper.vault_client }
  let(:config_path) { helper.config_path }
  let(:args) {["#{config_path}/encrypted_file"]}
  let(:random_value_one) { ('a'..'z').to_a.shuffle[0,8].join }

  before :each do
    # Write transit encrypted data to local file to test view command
    Sanctum::VaultTransit.write_to_file(vault_client, {args[0] => {"keyone" => "#{random_value_one}"}}, options[:vault][:transit_key])
  end

  # TODO This could probably be better
  it "views an encrypted file" do
    expect {described_class.new(options, args).run(command=nil)}.to output(/keyone: #{random_value_one}/).to_stdout
  end
end
