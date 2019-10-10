# frozen_string_literal: true

RSpec.describe Sanctum::Command::Init do
  let(:helper) { SanctumTest::Helpers.new }

  after do
    helper.cleanup
  end

  it 'generates example config file' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        described_class.new.run
        file_exists = File.exist?("#{dir}/sanctum.yaml")

        expect(file_exists).to be(true)
      end
    end
  end
end
