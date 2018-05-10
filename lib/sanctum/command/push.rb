require 'hashdiff'
require 'pathname'
require 'json'

module Sanctum
  module Command
    class Push
      include Colorizer
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def run
        phelp = PathsHelper.new
        @config_path = options[:config_file]
        vault_client = VaultClient.new(options[:vault][:url], options[:vault][:token]).vault_client

        apps = options[:sync]

        apps.each do |h|
          h.has_key?(:transit_key) ? transit_key = h[:transit_key] : transit_key = options[:vault][:transit_key]

          # Use command line if force: true
          if options[:cli][:force]
            force = options[:cli][:force]
          else
            h.has_key?(:force) ? force = h[:force] : force = options[:sanctum][:force]
          end

          # Recursively get local files for each prefix specified in sanctum.yaml
          local_paths = phelp.get_local_paths(File.join(File.dirname(@config_path), h[:path]))
          # Read each local file
          local_secrets = phelp.read_local_files(local_paths)
          # Decrypt local secrets
          local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)

          if force
            warn red("Forcefully pushing local secrets for #{h[:name]} to vault")
            local_secrets = local_secrets.map {|k, v| [k.gsub(File.join(File.dirname(@config_path), h[:path]), h[:prefix]), v] }.to_h
            VaultTransit.write_to_vault(vault_client, local_secrets)
          else
            # Get vault secrets (if they exist) for each prefix specified in sanctum.yaml and local paths
            # This means that we will only compare secrets/paths that exist in both locally and in vault.
            # We will not for example, see differences if a secret exists in vault but not locally.
            # TODO: Implement a sync command that ensures local and vault are in sync
            # Example: Sync would delete secrets that exist in vault but not locally

            # Map local_paths into vault_paths
            vault_paths = local_paths.map{|x| x.gsub(File.join(File.dirname(@config_path), h[:path]), "")}
            # Read secrets from vault
            vault_secrets = read_remote(vault_client, vault_paths, h[:prefix])
            # To make comparing a bit easier map vault_secrets paths back local_paths
            # Convert to json, then read, to make keys strings vs symbols
            vault_secrets = JSON(join_path(vault_secrets, h[:path]).to_json)
            # Compare
            compare_local_to_vault(vault_client, vault_secrets, local_secrets, transit_key, h)
          end
        end
      end

      def read_remote(vault_client, paths, prefix)
        tmp_hash = Hash.new
        paths.each do |k,v|
          p = File.join(prefix, k)
          unless vault_client.logical.read(p).nil?
            v = vault_client.logical.read(p).data
            tmp_hash["#{k}"] = v
          else
            next
          end
        end
        tmp_hash
      end

      # TODO Rename, so method doesn't match phelp.join_path
      def join_path(secrets, local_path)
        config_path = Pathname.new(@config_path)
        tmp_hash = Hash.new

        secrets.map do |p, v|
          p = config_path.dirname + Pathname.new(File.join(local_path, p))
          tmp_hash["#{p}"] = v
        end
        tmp_hash
      end

      def compare_local_to_vault(vault_client, vault_secrets, local_secrets, transit_key, h)
        if vault_secrets == local_secrets
          puts yellow("Application #{h[:name]}: contains no differences")
        else
          puts yellow("Application #{h[:name]}: contains the following differences")

          differences = HashDiff.best_diff(vault_secrets, local_secrets, delimiter: " => ", array_path: true)
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
            puts "Overwriting differences"

            #Only write changes
            local_secrets = only_changes(diff_paths, local_secrets)
            #Convert path back to vault prefix
            #TODO figure out a better way to do this...
            local_secrets = local_secrets.map {|k, v| [k.gsub(File.join(File.dirname(@config_path), h[:path]), h[:prefix]), v] }.to_h
            VaultTransit.write_to_vault(vault_client, local_secrets)
          end
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
