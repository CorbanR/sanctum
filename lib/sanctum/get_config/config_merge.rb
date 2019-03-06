require 'sanctum/get_config/config_file'
require 'sanctum/get_config/env'
require 'sanctum/get_config/hash_merger'
require 'sanctum/get_config/options'


module Sanctum
  module GetConfig
    class ConfigMerge

      using HashMerger
      attr_reader :config_file, :targets, :force

      def initialize(config_file: , targets: , force: )
        @config_file = config_file
        @targets = targets.split(/\,/).map(&:strip) unless targets.nil?
        @force = force
      end

      def default_options
        # default_options will search for config_file or take the path specified via cli
        DefaultOptions.new(config_file).run
      end

      def config_options
        config_options = ConfigFile.new(default_options[:config_file]).run
        # Check that targets specified via commandline actually exist in config_file and update config_options[:sync] array
        config_options = check_targets(targets, config_options) unless targets.nil?
        config_options
      end

      def env_options
        Env.new.run
      end

      def cli_options
        { cli: { targets: targets, force: force } }
      end

      def merge_options(default_options, config_options, env_options, cli_options)
        default_options.deep_merge(config_options).deep_merge(env_options).deep_merge(cli_options)
      end

      def final_options
        merge_options(default_options, config_options, env_options, cli_options)
      end

      def check_targets(targets, config_options)
        tmp_array = Array.new
        sync = config_options[:sync]

        targets.each do |t|
          sync.each do |h|
            tmp_array << h if h[:name] == t
          end
        end

        if tmp_array.empty?
          valid_targets = sync.map{|h| h[:name]}
          raise "Please specify at least one valid target\n Valid targets are #{valid_targets}"
        end

        config_options[:sync] = tmp_array
        config_options
      end


    end
  end
end
