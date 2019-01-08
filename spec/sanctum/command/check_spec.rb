RSpec.describe Sanctum::Command::Check do
  let(:config_path) {"#{Dir.tmpdir}/check"}
  let(:vault_token) {"514c55f0-c452-99e3-55e0-8301b770b92c"}
  let(:vault_addr) {"http://vault:8200"}
  let(:options) {
    {:config_file=>"#{config_path}/sanctum.yaml",
     :sanctum=>{:force=>false, :color=>false},
     :vault=>{:url=>vault_addr,
              :token=>vault_token,
              :transit_key=>"transit/keys/vault-test"},
              :sync=>[{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test"}],
              :cli=>{:targets=>nil, :force=>true}}
  }
  let(:vault_client) {Sanctum::VaultClient.build(vault_addr, vault_token)}
  let(:vault_env) { {"VAULT_ADDR" => vault_addr, "VAULT_TOKEN" => vault_token} }

  before :each do
    Sanctum::Colorizer.colorize = options[:sanctum][:color]
    # Clean up test generated data
    FileUtils.remove_entry_secure(config_path, force: true) if File.directory?(config_path)
    # Ensure vault server has started and is accepting connections
    Timeout::timeout(5){response = Net::HTTP.get_response(URI("#{vault_addr}/v1/sys/health")) rescue retry until response.kind_of? Net::HTTPSuccess}

    # Enable transit secrets mount
    vault_command(vault_env,"vault secrets enable transit")
    # Create a transit key
    vault_command(vault_env,"vault write -f transit/keys/vault-test")
    # Enable a generic secrets mount for testing
    vault_command(vault_env,"vault secrets enable -path=vault-test generic")

    # Create tmp path
    FileUtils.mkdir_p("#{config_path}/vault/vault-test/iad/dev/")
    # Write transit encrypted data to local file to test check command
    Sanctum::VaultTransit.write_to_file(vault_client, {"#{config_path}/vault/vault-test/iad/dev/env" => {"keyone" => "valueone"}}, options[:vault][:transit_key])
    # Write secrets to vault for testing check command
    vault_command(vault_env,"vault write vault-test/iad/prod/env keyone=valueone keytwo=valuetwo")
  end

  # TODO This could probably be better
  it "checks differences between local files and vault" do
    expect {described_class.new(options).run}.to output(/{"keyone"=>"valueone", "keytwo"=>"valuetwo"}/).to_stdout
  end
end
