# frozen_string_literal: true

require 'sanctum/config/default'

module Sanctum
  # Calculate sanctum config values
  class Config
    using HashUtils
    attr_reader :cli_options, :default_options

    class ConfigFileNotFound < StandardError; end
    class NoSyncTargetsDefined < StandardError; end
    class TargetsNotFound < StandardError; end

    def initialize(cli_options = {})
      @cli_options = parse_cli_options(cli_options)
      @default_options = Default.new(@cli_options).options
    end

    # Merge hashes to calculate final options value
    #
    # @return [Hash] of options
    #   * :config_file (String) the path to config
    #   * :sanctum (Hash) sanctum specifc options
    #     * :color (boolean)
    #     * :force (boolean) skip user interaction when running sync commands
    #   * :cli (Hash) the cli options
    #     * :config_file (String) the path to config
    #     * :targets (Array) targets passed via commandline
    #     * :force (boolean) skip user interaction when running sync commands
    #   * :vault (Hash) vault options
    #     * :token (String) the vault token
    #     * :addr (String) the vault address
    #     * :secrets_version (String,Integer) the secrets mount version
    #     * :transit_key (String) the transit key to use
    #   * :sync (Array<Hash>) defined list of targets
    #     * :name (String) the name of the target
    #     * :prefix (String) the vault prefix
    #     * :path (String) the local path
    #     * :vault (Hash) specify vault options to override per target
    def options
      # Using the config_file value from default_options as it is calculated by using
      # cli_options[:config_file] || path_search
      raise ConfigFileNotFound unless default_options.key?(:config_file)

      config_hash = load_config_file(default_options[:config_file])
      raise NoSyncTargetsDefined if config_hash.blank? || config_hash[:sync].blank?

      invalid_targets = invalid_cli_targets(cli_options[:targets], config_hash[:sync]) unless cli_options[:targets].blank?
      raise TargetsNotFound, invalid_targets.to_s unless invalid_targets.blank?

      default_options.deep_merge(config_hash)
    end

    private

    # Load sanctum.yaml
    #
    # @param [String] config_file the path of the config file
    # @return [Hash] of options parsed from config file
    def load_config_file(config_file)
      YAML.safe_load(File.read(config_file), [Symbol], symbolize_names: true).deep_compact
    rescue Psych::SyntaxError
      raise 'Please ensure your config file is formatted correctly. `sanctum init --help`'
    end

    # parse the cli options
    #
    # @param [Hash] options the cli options
    # @option options [String] :c location of the config file
    # @option options [String] :t comma seperated targets(as string)
    # @option options [Boolean] :force whether or not to bypass user interaction
    # @return [Hash] the cli options transformed to a more usable format
    def parse_cli_options(options)
      {
        config_file: (Pathname.new(options[:config_file]).realpath.to_s unless options[:config_file].nil?),
        targets: options[:targets],
        force: options[:force],
      }.compact
    end

    # Compare targets specified on the commandline with those defined in the config_file
    #
    # @param [Array<String>] cli_targets list of targets specified via commandline
    # @param [Array<Hash>] config_targets list of targets defined in config_file
    # @return [Array] of invalid targets
    def invalid_cli_targets(cli_targets, config_targets)
      cli_targets.reject do |target|
        config_targets.any? do |t|
          t[:name] == target
        end
      end
    end
  end
end
