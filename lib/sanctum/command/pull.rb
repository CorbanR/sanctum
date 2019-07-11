# frozen_string_literal: true

require 'pathname'

module Sanctum
  module Command
    class Pull < Base
      def run
        puts yellow("Running `pull` for the following targets: \n#{targets.map { |h| h.dig(:name) }.to_yaml.gsub("---\n", '')}")
        targets.each do |target|
          # Use command line if force: true
          force = options[:cli][:force] || target.fetch(:force) { options[:sanctum][:force] }

          # Recursively get vault secrets for each prefix specified in sanctum.yaml
          secrets_list = VaultSecrets.new(vault_client, target[:prefix], target[:secrets_version]).get_all
          secrets_list.each do |_k, v|
            vault_secrets = build_vault_secrets(v, [target[:path]])
            local_secrets = build_local_secrets(vault_secrets, target[:transit_key])

            # Compare secrets, if there are no differences continue to next target
            differences = compare_secrets(vault_secrets, local_secrets, target[:name], 'pull')
            next if differences.nil?

            # Get uniq array of Hashdiff returned paths
            diff_paths = differences.map { |x| x[1][0] }.uniq

            # Only sync the differences
            vault_secrets = only_changes(diff_paths, vault_secrets)

            if force
              # Write files to disk and encrypt with transit
              warn red("#{target[:name]}: Forcefully writing differences to disk(pull)")
              VaultTransit.write_to_file(vault_client, vault_secrets, target[:transit_key])
            else
              # Confirm with user, and write to local file if approved
              next unless confirmed_with_user?

              VaultTransit.write_to_file(vault_client, vault_secrets, target[:transit_key])
            end
          end
        end
      end

      def create_paths(paths)
        paths.each do |k, _v|
          k = Pathname.new(k)
          k.dirname.mkpath unless k.dirname.exist?
        end
      end

      def build_vault_secrets(tree, path)
        # Build local paths based on vault_prefix(tree) and paths specified in sanctum.yaml
        vault_secrets = build_path(tree, path)

        # Join the path array to create a path
        vault_secrets = join_path(vault_secrets, config_file)

        # Ensure local paths exist, relative to sanctum.yaml if they don't create them
        create_paths(vault_secrets)
        vault_secrets
      end

      def build_local_secrets(vault_secrets, transit_key)
        # read_local_files uses vault_secrets paths to create a new hash with local paths and values.
        # This means that we will only compare secrets/paths that exist in both vault and locally.
        # We will not for example, see differences if a file exists locally but not in vault.
        local_secrets = read_local_files(vault_secrets)
        # Decrypt local_secrets
        local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)
        local_secrets
      end
    end
  end
end
