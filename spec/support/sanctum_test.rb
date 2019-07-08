require "pathname"
require "tmpdir"

module SanctumTest
  class Helpers
    attr_reader :options, :config_path, :vault_client, :vault_env

    def initialize(override_options: {})
      @options = get_sanctum_options(override_options)
      # Path where sanctum config is located
      @config_path = Pathname.new(options.dig(:config_file)).parent.to_path
      @vault_client = Sanctum::VaultClient.build(options.dig(:vault).dig(:url), options.dig(:vault).dig(:token))
      @vault_env = { "VAULT_ADDR" => options.dig(:vault).dig(:url), "VAULT_TOKEN" => options.dig(:vault).dig(:token) }

      # Disable color for testing
      Sanctum::Colorizer.colorize = options[:sanctum][:color]
    end

    def vault_command(env={}, command=nil, stdout={ [:out]=>"/dev/null" })
      env = vault_env.merge(env)
      system(env, command, stdout)
    end

    def vault_setup(secrets_engine: "generic", secrets_version: nil)
      # Ensure vault is up and running
      Timeout::timeout(5){response = Net::HTTP.get_response(URI("#{options.dig(:vault).dig(:url)}/v1/sys/health")) rescue retry until response.kind_of? Net::HTTPSuccess}

      # Enable transit backend
      vault_command(vault_env, "vault secrets enable transit")
      # Create transit key
      vault_command(vault_env, "vault write -f #{options.dig(:sanctum).dig(:transit_key)}")
      # Create secrets mount
      if secrets_version
        vault_command(vault_env, "vault secrets enable -path=#{options.dig(:sync).first.dig(:prefix)} -version=#{secrets_version} #{secrets_engine}")
      else
        vault_command(vault_env, "vault secrets enable -path=#{options.dig(:sync).first.dig(:prefix)} #{secrets_engine}")
      end
    end

    def vault_cleanup
      # Disable transit backend
      vault_command(vault_env, "vault secrets disable transit")
      # Disable secrets mount
      vault_command(vault_env, "vault secrets disable #{options.dig(:sync).first.dig(:prefix)}")

      # Cleanup config_file and targets local paths
      if File.file?(options[:config_file])
        options.dig(:sync).each do |f|
          FileUtils.rm_rf([options[:config_file], "#{config_path}/#{f[:path]}/"], secure: true)
        end
      end
    end

    def default_sanctum_options
      {
        config_file: "#{Dir.mktmpdir}/sanctum.yaml",
        sanctum: {
          force: false,
          color: false,
          transit_key: "transit/keys/vault-test",
          secrets_version: "auto",
        },
        vault: {
          url: "http://vault:8200",
          token: "514c55f0-c452-99e3-55e0-8301b770b92c",
        },
        sync: [
          {
            name: "vault-test",
            prefix: "vault-test",
            path: "vault/vault-test",
          },
        ],
        cli: {
          targets: nil,
          force: true,
        },
      }
    end

    # Use Sanctum::GetConfig::ConfigMerge to read generated test sanctum.yaml
    def get_sanctum_options(override_options)
      default_options = default_sanctum_options.merge(override_options)
      config_file = default_options.dig(:config_file)
      File.write(config_file, default_options.to_yaml) unless File.file?(config_file)
      Sanctum::GetConfig::ConfigMerge.new(config_file: config_file, targets: nil, force: nil).final_options
    end
  end
end
