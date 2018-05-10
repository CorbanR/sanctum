module Sanctum
  module Command
    class Check
      include Colorizer
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def run
        phelp = PathsHelper.new
        vault_client = VaultClient.new(options[:vault][:url], options[:vault][:token]).vault_client

        apps = options[:sync]

        apps.each do |h|
          # Use app specific transit key if specified via config
          h.has_key?(:transit_key) ? transit_key = h[:transit_key] : transit_key = options[:vault][:transit_key]
          # Recursively get local files for each prefix specified in sanctum.yaml
          local_paths = phelp.get_local_paths(File.join(File.dirname(options[:config_file]), h[:path]))
          # Read each file
          local_secrets = phelp.read_local_files(local_paths)
          # Decrypt each secret
          @local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)

          # Recursively get vault secrets for each prefix specified in sanctum.yaml
          VaultSecrets.get(vault_client, h[:prefix]).each do |k,v|
            # Build local paths based on prefix and paths specified in sanctum.yaml
            vault_secrets = phelp.build_path(v, [h[:path]])
            # Join the path array to create a path
            @vault_secrets = phelp.join_path(vault_secrets, options[:config_file])
          end
          compare_local_to_vault(@vault_secrets, @local_secrets, h[:name])
        end
      end

      def compare_local_to_vault(vault_secrets, local_secrets, name)
        if vault_secrets == local_secrets
          puts yellow("Application #{name}: contains no differences")
        else
          puts yellow("Application #{name}: differences If you were to pull from vault")
          HashDiff.best_diff(local_secrets, vault_secrets, delimiter: " => ").each do |diff|
            if diff[0] == "+"
              puts green("#{diff[0] + diff[1]} => #{diff[2]}")
            else
              puts red("#{diff[0] + diff[1]} => #{diff[2]}")
            end
          end

          puts yellow("Application #{name}: differences If you were push to vault")
          HashDiff.best_diff(vault_secrets, local_secrets, delimiter: " => ").each do |diff|
            if diff[0] == "+"
              puts green("#{diff[0] + diff[1]} => #{diff[2]}")
            else
              puts red("#{diff[0] + diff[1]} => #{diff[2]}")
            end
          end
        end

      end

    end
  end
end
