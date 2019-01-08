RSpec.describe Sanctum::Command::Create do
  let(:config_path) {"#{Dir.tmpdir}/create"}
  let(:vault_token) {"514c55f0-c452-99e3-55e0-8301b770b92c"}
  let(:vault_addr) {"http://vault:8200"}
  let(:vault_env) { {"VAULT_ADDR" => vault_addr, "VAULT_TOKEN" => vault_token} }
  let(:vault_client) {Sanctum::VaultClient.build(vault_addr, vault_token)}
  let(:args) {["#{config_path}/encrypted_file"]}
  let(:options) {
    {:config_file=>"#{config_path}/sanctum.yaml",
     :sanctum=>{:force=>false, :color=>false},
     :vault=>{:url=>vault_addr,
              :token=>vault_token,
              :transit_key=>"transit/keys/vault-test"},
              :sync=>[{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test"}],
              :cli=>{:targets=>nil, :force=>true}}
  }

  before :each do
    Sanctum::Colorizer.colorize = options[:sanctum][:color]
    #Clean up generated test file
    FileUtils.remove_entry_secure(config_path, force: true) if File.directory?(config_path)
    # Ensure vault server has started and is accepting connections
    Timeout::timeout(5){response = Net::HTTP.get_response(URI("#{vault_addr}/v1/sys/health")) rescue retry until response.kind_of? Net::HTTPSuccess}

    # Enable transit secrets mount
    vault_command(vault_env,"vault secrets enable transit")
    # Create a transit key
    vault_command(vault_env,"vault write -f transit/keys/vault-test")
    # Create tmp folder
    FileUtils.mkdir_p("#{config_path}")
  end

  it "creates an encrypted file" do
    described_class.new(options, args).run do |tmp_file|
      File.write(tmp_file.path, "hey: dude")
    end

    encrypted_file = args[0]
    decrypted_contents = Sanctum::VaultTransit.decrypt(vault_client, {encrypted_file => File.read(encrypted_file)}, options[:vault][:transit_key])


    expect(File.file?(encrypted_file)).to be(true)
    expect(File.read(encrypted_file)).to include("vault")
    expect(decrypted_contents).to eq({encrypted_file => {"hey" => "dude"}})
  end
end
