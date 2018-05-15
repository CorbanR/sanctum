module Sanctum
  module Command
    class Check < Base

      def run
        phelp = PathsHelper.new

        apps.each do |h|
          # Recursively get local files for each prefix specified in sanctum.yaml
          local_paths = phelp.get_local_paths(File.join(File.dirname(config_file), h[:path]))
          # Read each file
          local_secrets = phelp.read_local_files(local_paths)
          # Decrypt each secret
          @local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)

          # Recursively get vault secrets for each prefix specified in sanctum.yaml
          secrets_list = VaultSecrets.new(vault_client, h[:prefix]).get
          secrets_list.each do |k, v|
            # Build local paths based on prefix and paths specified in sanctum.yaml
            vault_secrets = phelp.build_path(v, [h[:path]])
            # Join the path array to create a path
            @vault_secrets = phelp.join_path(vault_secrets, config_file)
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
