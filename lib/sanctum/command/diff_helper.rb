require 'hashdiff'

module Sanctum
  module Command
    module DiffHelper

      def hash_diff(first_hash, second_hash)
        # Recently changed how data is written to local system and vault
        # TODO: The transform_values can be removed at a later date
        first_hash = first_hash.each { |_, v| v.transform_values!(&:to_s) }
        second_hash = second_hash.each { |_, v| v.transform_values!(&:to_s) }

        differences = HashDiff.best_diff(first_hash, second_hash, delimiter: " => ", array_path: true)

        differences.each do |diff|
          if diff[0] == "+"
            puts green("#{diff[0].to_s + diff[1].join(" => ").to_s} => #{diff[2]}")
          else
            puts red("#{diff[0].to_s + diff[1].join(" => ").to_s} => #{diff[2]}")
            # If a secret is changed, we should show the change
            puts green("+#{diff[1].join(" => ").to_s} => #{diff[3]}") if diff.fetch(3, false)
          end
        end
        differences
      end

      def compare_secrets(vault_secrets, local_secrets, name, direction="both")
        # Recently changed how data is written to local system and vault
        # TODO: The transform_values can be removed at a later date
        vault_secrets = vault_secrets.each { |_, v| v.transform_values!(&:to_s) }
        local_secrets = local_secrets.each { |_, v| v.transform_values!(&:to_s) }

        if vault_secrets == local_secrets
          warn yellow("Target #{name}: contains no differences")
        else
          case direction
          when "pull"
            puts yellow("Target #{name}: differences pulling from vault")
            hash_diff(local_secrets, vault_secrets)
          when "push"
            puts yellow("Target #{name}: differences pushing to vault")
            hash_diff(vault_secrets, local_secrets)
          when "both"
            puts yellow("Target #{name}: differences pulling from vault")
            hash_diff(local_secrets, vault_secrets)

            puts yellow("Target #{name}: differences pushing to vault")
            hash_diff(vault_secrets, local_secrets)
          end
        end
      end

      def confirmed_with_user?
        puts yellow("\nWould you like to continue?: ")
        question = STDIN.gets.chomp.upcase

        if ["Y", "YES"].include? question
          puts yellow("Overwriting differences")
          true
        else
          warn yellow("Skipping....\n")
          false
        end
      end

      # Array is a unique list of paths built from the differences of hash1 and hash2.
      #   See diff_paths variable in push or pull command
      # Hash will be all local, or vault secrets.
      # We then build a new hash that contains only the k,v needed to sync (to or from vault)
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
