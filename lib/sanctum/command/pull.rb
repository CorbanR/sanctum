require 'pathname'
require 'hashdiff'

module Sanctum
  module Command
    class Pull < Base

      def run
        phelp = PathsHelper.new

        apps.each do |h|
          # Use command line if force: true
          if options[:cli][:force]
            force = options[:cli][:force]
          else
            force = h.fetch(:force) {options[:sanctum][:force]}
          end

          # Recursively get vault secrets for each prefix specified in sanctum.yaml
          secrets_list = VaultSecrets.new(vault_client, h[:prefix]).get
          secrets_list.each do |k,v|
            # Build local paths based on prefix and paths specified in sanctum.yaml
            vault_secrets = phelp.build_path(v, [h[:path]])

            # Join the path array to create a path
            vault_secrets = phelp.join_path(vault_secrets, config_file)

            # Ensure local paths exist, relative to sanctum.yaml if they don't create them
            create_paths(vault_secrets)

            # Using vault_secrets path keys to create a new hash with local paths and values.
            # This means that we will only compare secrets/paths that exist in both vault and locally.
            # We will not for example, see differences if a file exists locally but not in vault.
            local_secrets = phelp.read_local_files(vault_secrets)
            if force
              # Write files to disk and encrypt with transit
              warn red("Pulling vault secrets for #{h[:name]} and forcefully writing to local files")
              VaultTransit.write_to_file(vault_client, vault_secrets, transit_key)
            else
              # Decrypt local_secrets and compare differences
              local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)
              compare_local_to_vault(vault_secrets, local_secrets, h[:name])
            end

          end

        end
      end

      def create_paths(paths)
        paths.each do |k,v|
          k = Pathname.new(k)
          unless k.dirname.exist?
            k.dirname.mkpath
          end
        end
      end

      def compare_local_to_vault(vault_secrets, local_secrets, name)
        unless vault_secrets == local_secrets
          puts yellow("Application #{name}: contains the following differences")
          puts

          differences = HashDiff.best_diff(local_secrets, vault_secrets, delimiter: " => ", array_path: true)
          #Get uniq array of HashDiff returned paths
          diff_paths = differences.map{|x| x[1][0]}.uniq

          differences.each do |diff|
            if diff[0] == "+"
              puts green("#{diff[0].to_s + diff[1].join(" => ").to_s} => #{diff[2]}")
            else
              puts red("#{diff[0].to_s + diff[1].join(" => ").to_s} => #{diff[2]}")
            end
          end

          puts
          puts yellow("Would you like to continue?: ")
          question = STDIN.gets.chomp.upcase


          unless ["Y", "YES"].include? question
            raise yellow("Quitting....")
          else
            puts yellow("Overwriting differences")

            vault_secrets = only_changes(diff_paths, vault_secrets)
            VaultTransit.write_to_file(vault_client, vault_secrets, transit_key)
          end
        else
          puts yellow("Application #{name}: contains no differences")
        end
      end

      def only_changes(array, hash)
        tmp_hash = Hash.new
        array.each do |a|
          hash.each do |k, v|
            tmp_hash[k] = v if a == k
          end
        end
        tmp_hash
      end

    end
  end
end
