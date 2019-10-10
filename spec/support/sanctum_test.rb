# frozen_string_literal: true

require 'pathname'
require 'tmpdir'

module SanctumTest
  class Helpers
    VAULT_ADDR = 'http://vault:8200'
    VAULT_TOKEN = '514c55f0-c452-99e3-55e0-8301b770b92c'
    VAULT_TRANSIT_KEY = 'transit/keys/vault-test'
    VAULT_PREFIX = 'vault-test'
    LOCAL_PATH = 'vault/vault-test'
    attr_reader :vault_client, :vault_env

    def initialize
      Sanctum::Colorizer.colorize = false
      @vault_client = Sanctum::VaultClient.build(VAULT_ADDR, VAULT_TOKEN)
      @vault_env = { 'VAULT_ADDR' => VAULT_ADDR, 'VAULT_TOKEN' => VAULT_TOKEN }
    end

    def vault_command(env = {}, command = nil, stdout = { [:out] => '/dev/null' })
      env = vault_env.merge(env)
      system(env, command, stdout)
    end

    def vault_setup(secrets_engine: 'generic', secrets_version: nil)
      # Ensure vault is up and running
      Timeout.timeout(5) do
        response = begin
                     Net::HTTP.get_response(URI("#{VAULT_ADDR}/v1/sys/health"))
                   rescue StandardError
                     retry
                   end until response.is_a? Net::HTTPSuccess
      end

      # Enable transit backend
      vault_command(vault_env, 'vault secrets enable transit')
      # Create transit key
      vault_command(vault_env, "vault write -f #{VAULT_TRANSIT_KEY}")
      # Create secrets mount
      if secrets_version
        vault_command(vault_env, "vault secrets enable -path=#{VAULT_PREFIX} -version=#{secrets_version} #{secrets_engine}")
      else
        vault_command(vault_env, "vault secrets enable -path=#{VAULT_PREFIX} #{secrets_engine}")
      end
    end

    def vault_cleanup
      # Disable transit backend
      vault_command(vault_env, 'vault secrets disable transit')
      # Disable secrets mount
      vault_command(vault_env, "vault secrets disable #{VAULT_PREFIX}")

      # Cleanup config_file and targets local paths
      if File.file?(options[:config_file])
        options.dig(:sync).each do |f|
          FileUtils.rm_rf([options[:config_file], "#{config_path}/#{f[:path]}/"], secure: true)
        end
      end
    end

    def cleanup
      return unless instance_variable_defined?(:@test_file)

      test_file.close
      test_file.unlink
    end

    def generate_test_file(config_overrides = {})
      if config_overrides.empty?
        default_options = Sanctum::Config.new(config_file: test_file.path).default_options
        test_file.write(default_options.merge(test_values).to_yaml)
      else
        test_file.write(config_overrides.to_yaml)
      end
      test_file.rewind
    end

    def test_values
      {
        sync: [{ name: VAULT_PREFIX, prefix: VAULT_PREFIX, path: LOCAL_PATH }],
        vault: { addr: VAULT_ADDR, token: VAULT_TOKEN, transit_key: VAULT_TRANSIT_KEY },
      }
    end

    def test_file
      @test_file ||= Tempfile.new('sanctum.yaml')
    end
  end
end
