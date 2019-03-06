require 'pathname'
require 'json'

module Sanctum
  module Command
    class Push < Base

      def run
        targets.each do |target|
          # Use command line if force: true
          if options[:cli][:force]
            force = options[:cli][:force]
          else
            force = target.fetch(:force) {options[:sanctum][:force]}
          end

          # Build array of local paths by recursively searching for local files for each path specified in sanctum.yaml
          local_paths = get_local_paths(File.join(File.dirname(config_file), target[:path]))

          local_secrets = build_local_secrets(local_paths, target[:transit_key])
          vault_secrets = build_vault_secrets(local_paths, target[:prefix], target[:path], target[:secrets_version])

          # Compare secrets
          # vault_secrets prefix have been mapped to local_paths to make comparison easier
          differences = compare_secrets(vault_secrets, local_secrets, target[:name], "push")
          next if differences.nil?

          # Get uniq array of HashDiff returned paths
          diff_paths = differences.map{|x| x[1][0]}.uniq

          # Only write changes
          vault_secrets = only_changes(diff_paths, local_secrets)

          #Convert paths back to vault prefix so we can sync
          vault_secrets = vault_secrets.map {|k, v| [k.gsub(File.join(File.dirname(config_file), target[:path]), target[:prefix]), v] }.to_h

          if force
            warn red("#{target[:name]}: Forcefully writing differences to vault(push)")
            VaultTransit.write_to_vault(vault_client, vault_secrets, target[:secrets_version])
          else
            #Confirm with user, and write to local file if approved
            next unless confirmed_with_user?
            VaultTransit.write_to_vault(vault_client, vault_secrets, target[:secrets_version])
          end
        end
      end

      # Right now this duplicates a bit of logic that already exists in
      # VaultSecrets client.
      # TODO: remove this method once code is rearranged
      def read_remote(paths, prefix, secrets_version)
        tmp_hash = Hash.new
        paths.each do |k,v|
          p = File.join(prefix, k)
          unless vault_client.logical.read(p).nil?
            v = secrets_version == "2" ? vault_client.logical.read(p).data[:data] : vault_client.logical.read(p).data
            tmp_hash["#{k}"] = v
          else
            next
          end
        end
        tmp_hash
      end

      def map_local_path(secrets_hash, local_path)
        config_path = Pathname.new(config_file)
        tmp_hash = Hash.new

        secrets_hash.map do |p, v|
          p = config_path.dirname + Pathname.new(File.join(local_path, p))
          tmp_hash["#{p}"] = v
        end
        tmp_hash
      end

      def build_local_secrets(local_paths, transit_key)
        # Read each local file
        local_secrets = read_local_files(local_paths)
        # Decrypt local secrets
        local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)
      end

      def build_vault_secrets(local_paths, target_prefix, target_path, secrets_version)
        # Map local_paths into vault_paths
        vault_paths = local_paths.map{|x| x.gsub(File.join(File.dirname(config_file), target_path), "")}

        # Get vault secrets (if they exist) for each vault prefix specified in sanctum.yaml that also maps to a local path
        # This means that we will only compare secrets/paths that exist both locally and in vault.
        # We will not for example, see differences if a secret exists in vault but not locally.

        # Read secrets from vault
        vault_secrets = read_remote(vault_paths, target_prefix, secrets_version)

        # To make comparing a bit easier map vault_secrets prefixs back local_paths
        # Convert to json, then read, to make keys strings vs symbols
        vault_secrets = JSON(map_local_path(vault_secrets, target_path).to_json)
      end

    end
  end
end
