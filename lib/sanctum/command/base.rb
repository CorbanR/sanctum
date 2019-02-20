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

      attr_reader :options, :args, :transit_key, :targets, :config_file

      def initialize(options={}, args=[])
        @options = options.to_h
        @args = args

        @transit_key = options.fetch(:vault).fetch(:transit_key)
        # TODO: Fix, way to much is happening to targets in this initializer!
        @targets = update_prefix_or_path(
          set_secrets_version(
            remove_trailing_slash(
              options.fetch(:sync)
            )
          )
        )
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

      # Internal: automatically detect the api version of the secrets mount
      # and adds :secrets_version to hash if it doesn't exist
      #
      # Parameter: is an array of hashes: [{}, {}]
      # Returns array of hashes: [{:name=>"vault-test", :prefix=>"vault-test", :path=>"vault/vault-test", :secrets_version=>"2"},{}]
      def set_secrets_version(targets)
        mounts_hash = mounts_info

        targets.each do |h|
          if h.key?(:secrets_version)
            # Ensure value is a string
            h[:secrets_version] = h[:secrets_version].to_s
            next
          end

          # If mount options is nil default to api version 1 otherwise use version value
          # generic mounts will not have a version specified
          if mounts_hash.dig(:data, :secret, "#{h[:prefix]}/".to_sym, :options).nil?
            h[:secrets_version] = "1"
          else
            h[:secrets_version] = mounts_hash.dig(:data, :secret, "#{h[:prefix]}/".to_sym, :options, :version).to_s
          end
        end
      end

      # Internal, update prefix or path, add `/data` if secrets_version == "2"
      # Parameter is an array of hashes: [{}, {}]
      # Returns array of hashes: [{:name=>"vault-test", :prefix=>"vault-test/data", :path=>"vault/vault-test/data", :secrets_version=>"2"},{}]
      def update_prefix_or_path(targets)
        targets.each do |h|
          next unless h[:secrets_version] == "2"

          h[:prefix] = h[:prefix].include?("/data") ? h[:prefix] : "#{h[:prefix]}/data"
          h[:path] = h[:path].include?("/data") ? h[:path] : "#{h[:path]}/data"
        end
      end

      def remove_trailing_slash(targets)
        targets.each do |h|
          h[:prefix] = h[:prefix].chomp("/")
          h[:path] = h[:path].chomp("/")
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
