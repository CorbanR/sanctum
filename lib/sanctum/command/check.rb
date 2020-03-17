# frozen_string_literal: true

module Sanctum
  module Command
    #:nodoc:
    class Check < Base
      def run
        targets.each do |target|
          # Recursively get local files for each prefix specified in sanctum.yaml
          local_paths = get_local_paths(File.join(File.dirname(config_file), target[:path]))
          # Read each file
          local_secrets = read_local_files(local_paths)
          # Decrypt each secret
          local_secrets = Adapter::Vault::Transit.decrypt(vault_client, local_secrets, target[:transit_key])

          # Recursively get vault secrets for each prefix specified in sanctum.yaml
          secrets_list = Adapter::Vault::Secrets.new(vault_client, target[:prefix], target[:secrets_version]).get_all

          # Only one entry in this hash (which will be the target).
          tree = secrets_list.values.first
          # Build local paths based on prefix and paths specified in sanctum.yaml
          vault_secrets = build_path(tree, [target[:path]])
          # Join the path array to create a path
          vault_secrets = join_path(vault_secrets, config_file)
          compare_secrets(vault_secrets, local_secrets, target[:name])
        end
      end
    end
  end
end
