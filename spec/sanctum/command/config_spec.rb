RSpec.describe Sanctum::Command::Config do
  let(:config_path) {Dir.tmpdir}

  before :each do
    Sanctum::Colorizer.colorize = false
    # Clean up test generated data
    FileUtils.remove_entry_secure("#{config_path}/sanctum.yaml", force: true) if File.file?("#{config_path}/sanctum.yaml")
  end

  it "generates example config file" do
    Dir.chdir(config_path){described_class.new.run}
    file_exists = File.exist?("#{config_path}/sanctum.yaml")
    expect(file_exists).to be(true)
  end
end
