# frozen_string_literal: true

RSpec.describe Sanctum::Command::Init do
  let(:helper) { SanctumTest::Helpers.new }
  let(:config_path) { helper.config_path }

  before do
    # Clean up test generated data
    helper.vault_cleanup
  end

  it 'generates example config file' do
    Dir.chdir(config_path) { described_class.new.run }
    file_exists = File.exist?("#{config_path}/sanctum.yaml")
    expect(file_exists).to be(true)
  end
end