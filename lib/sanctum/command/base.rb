require 'sanctum/command/diff_helper'
require 'sanctum/command/editor_helper'
require 'sanctum/command/paths_helper'

module Sanctum
  module Command
    class Base
      include Colorizer
      include DiffHelper
      include EditorHelper
      include PathsHelper

      attr_reader :options, :args, :targets, :config_file

      def initialize(options={}, args=[])
        @options = options.to_h
        @args = args
        @targets = update_targets(options.fetch(:sync))
        @config_file = options.fetch(:config_file)
      end

      def vault_client
        @vault_client ||= VaultClient.build(options[:vault][:url], options[:vault][:token])
      end

      private
      # TODO: Fix! This is a bit hacky, will update once vault-ruby gets updated with better support for v2 api
      # Internal: gets information about mounts that the user has permissions on
      # Returns: hash
      def mounts_info
        @mounts_info ||= vault_client.request(:get, "/v1/sys/internal/ui/mounts")
      rescue Vault::VaultError
        unable_to_determine_version
        raise
      end

      # TODO: Most of this stuff should probably be done in a separate class, or even back in Samctum::GetConfig
      # Internal: Modifies each target with some additional logic
      # Returns: hash
      def update_targets(targets)
        default_transit_key = options.fetch(:sanctum).fetch(:transit_key, nil)
        default_secrets_version = options.fetch(:sanctum).fetch(:secrets_version)

        # TODO: make this better
        # remove_trailing_slash needs to run first, as some of the other logic in other methods
        # rely on it
        targets = remove_trailing_slash(targets)
        targets = set_secrets_version(targets, default_secrets_version)
        targets = set_transit_key(targets, default_transit_key)
        targets = update_prefix(targets)
        targets
      end

      # Internal: automatically detect the api version of the secrets mount
      # and adds :secrets_version to hash if it doesn't exist
      #
      # Parameter: is an array of hashes: [{}, {}]
      # Returns array of hashes: [{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test", :secrets_version=>"2"},{}]
      def set_secrets_version(targets, default_secrets_version)
        targets.each do |h|
          if h.key?(:secrets_version)
            # Ensure value is a string
            h[:secrets_version] = h[:secrets_version].to_s
            next
          end

          if default_secrets_version == "auto"
            mounts_hash = mounts_info
            # Use the root path to determine secrets_version
            prefix = "#{h[:prefix].lines('/').first}"
            prefix = prefix.include?("/") ? prefix.to_sym : "#{prefix}/".to_sym

            # If mount options is nil default to api version 1 otherwise use version value
            # generic mounts will not have a version specified
            if mounts_hash.dig(:data, :secret, prefix, :options).nil?
              h[:secrets_version] = "1"
            else
              h[:secrets_version] = mounts_hash.dig(:data, :secret, prefix, :options, :version).to_s
            end
          else
            h[:secrets_version] = default_secrets_version
          end
        end
      end

      # Internal sets default transit_key if :transit_key doesn't exist in hash
      #
      # Parameter: is an array of hashes: [{}, {}]
      # Returns array of hashes: [{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test", :secrets_version=>"2", :transit_key=>"transit/keys/vault-test"},{}]
      def set_transit_key(targets, default_transit_key)
        targets = targets.each do |h|
          if h.key?(:transit_key)
            # Ensure value is a string
            h[:transit_key] = h[:transit_key].to_s
            next
          else
            h[:transit_key] = default_transit_key.to_s
          end
        end

        raise "transit_key must be specified under sanctum defaults, or on a per target bases" if targets.any?{ |h| h.dig(:transit_key).nil? }
        targets
      end

      # Internal, update prefix , add `/data` if secrets_version == "2"
      # Parameter is an array of hashes: [{}, {}]
      # Returns array of hashes: [{:name=>"vault-test", :prefix=>"vault-test/data", :path=>"vault/vault-test", :secrets_version=>"2"},{}]
      def update_prefix(targets)
        targets.each do |h|
          next unless h[:secrets_version] == "2"

          # Super gross..., split path into an array
          path_array = h[:prefix].lines("/")
          # Add `data/` to the right place in the path if it's not already there
          if path_array.count == 1
            h[:prefix] = path_array.insert(1, "/data").join
          else
            h[:prefix] = path_array.include?("data/") ? path_array.join : path_array.insert(1, "data/").join
          end
        end
      end

      def remove_trailing_slash(targets)
        targets.each do |h|
          h[:prefix] = h[:prefix].chomp("/")
          h[:path] = h[:path].chomp("/")
          h[:transit_key] = h[:transit_key].chomp("/") if h.key?(:transit_key)
        end
      end

      def unable_to_determine_version
        warn red(
          "Unable to automatically gather info about mounts. This maybe due to vault connectivity or permissions"\
          "\nTo list info about mounts you may need to have following permissions added"\
          "\npath \"sys/internal/ui/mounts\" { capabilities = [\"read\"] }"\
          "\nAlternitivley add `secrets_version: <version>` for each target specified in sanctum.yaml to bypass autodetect"
        )
      end
    end
  end
end
