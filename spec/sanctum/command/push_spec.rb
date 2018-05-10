RSpec.describe Sanctum::Command::Push do
  let(:config_path) {"#{Dir.tmpdir}/push"}
  let(:vault_token) {"514c55f0-c452-99e3-55e0-8301b770b92c"}
  let(:vault_addr) {"http://127.0.0.1:8200"}
  let(:options) {
    {:config_file=>"#{config_path}/sanctum.yaml",
     :sanctum=>{:force=>false, :color=>false},
     :vault=>{:url=>vault_addr,
              :token=>vault_token,
              :transit_key=>"transit/keys/vault-test"},
              :sync=>[{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test"}],
              :cli=>{:targets=>nil, :force=>true}}
  }
  let(:vault_client) {Sanctum::VaultClient.new(vault_addr, vault_token).vault_client}
  let(:vault_env) { {"VAULT_ADDR" => vault_addr, "VAULT_TOKEN" => vault_token} }

  before :each do
    Sanctum::Colorizer.colorize = options[:sanctum][:color]
    # Clean up test generated data
    FileUtils.remove_entry_secure(config_path, force: true) if File.directory?(config_path)
    # Start vault server
    @pid = Process.spawn("vault", "server", "-dev", "-dev-root-token-id=#{vault_token}", [:out, :err]=>"/dev/null")
    # Ensure vault server has started and is accepting connections
    Timeout::timeout(5){response = Net::HTTP.get_response(URI("#{vault_addr}/v1/sys/health")) rescue retry until response.kind_of? Net::HTTPSuccess}

    # Enable transit secrets mount
    vault_command(vault_env,"vault secrets enable transit")
    # Create a transit key
    vault_command(vault_env,"vault write -f transit/keys/vault-test")
    # Enable a generic secrets mount for testing
    vault_command(vault_env,"vault secrets enable -path=vault-test generic")
    # Write transit encrypted data to a file to test push command
    FileUtils.mkdir_p("#{config_path}/vault/vault-test/iad/dev/")
    Sanctum::VaultTransit.write_to_file(vault_client, {"#{config_path}/vault/vault-test/iad/dev/env" => {"keyone" => "valueone"}}, options[:vault][:transit_key])
  end

  after :each do
    Process.kill("INT", @pid)
    Process.wait(@pid)
  end

  it "reads local secrets and pushes to vault" do
    described_class.new(options).run
    vault_secret = vault_client.logical.read("vault-test/iad/dev/env").data
    expect(vault_secret).to eq({:keyone=>"valueone"})
  end
end
