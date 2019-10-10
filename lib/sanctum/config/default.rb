# frozen_string_literal: true

module Sanctum
  # nodoc:
  class Config
    using HashUtils
    # Calculates the default config for sanctum
    class Default
      # @return [Hash] the default options
      attr_reader :options

      def initialize(cli_options = {})
        @options = default_options(cli_options)
      end

      private

      # Calculate the default options
      #
      # @param [Hash] cli_options the cli options
      # @option cli_options [String] :config_file the path of sanctum.yaml
      # @option cli_options [Array<String>] :targets the specified targets
      # @option cli_options [Boolean] :force whether or not to bypass user interaction
      # @return [Hash] the cli options transformed to a more usable format
      #
      # @return [Hash] of defaults
      def default_options(cli_options)
        {
          config_file: cli_options[:config_file] || config_file_search,
          cli: cli_options,
          sanctum: { color: true, force: false },
          vault: vault_defaults,
          sync: [],
        }.deep_compact
      end

      # Calculate the vault default vaules
      #
      # @return [Hash] the vault default values
      def vault_defaults
        {
          token: vault_token,
          addr: ENV.fetch('VAULT_ADDR') { 'http://127.0.0.1:8200' },
          secrets_version: 'auto',
          transit_key: nil,
        }
      end

      # Search for config_file if one wasn't specified via the commandline
      #
      # @return [String, nil] the path of sanctum.yaml if found, otherwise nil.
      def config_file_search
        Pathname.new(Dir.pwd).ascend do |p|
          return "#{p}/sanctum.yaml" if File.file?("#{p}/sanctum.yaml")
        end
      end

      # Sets vault token
      #
      # If ENV var is set use that, otherwise try reading .vault-token file
      #
      # @return [String, nil]
      def vault_token
        return ENV['VAULT_TOKEN'] if ENV['VAULT_TOKEN']

        token_file = "#{Dir.home}/.vault-token"
        File.read(token_file) if File.file?(token_file) && File.readable?(token_file)
      end
    end
  end
end
