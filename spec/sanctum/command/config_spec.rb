RSpec.describe Sanctum::Command::Config do
  let(:helper) {SanctumTest::Helpers.new}
  let(:config_path) { helper.config_path }

  before :each do
    # Clean up test generated data
    helper.vault_cleanup
  end

  it "generates example config file" do
    Dir.chdir(config_path){described_class.new.run}
    file_exists = File.exist?("#{config_path}/sanctum.yaml")
    expect(file_exists).to be(true)
  end
end
