# frozen_string_literal: true

module Sanctum
  module GetConfig
    class ConfigFile
      attr_reader :config_file

      def initialize(config_file = nil)
        raise 'Please create or specify a config file. `sanctum config --help`' if config_file.nil?
        raise 'Config file not found' unless File.file?(config_file)

        @config_file = config_file
      end

      def run
        config_hash = load_config_file(config_file)
        if config_hash.empty? || config_hash[:sync].nil?
          raise "Please specify at least one sync target in your config file: #{config_file}"
        else
          config_hash
        end
      end

      def load_config_file(config_file)
        config_hash = YAML.load_file(config_file)
        config_hash.compact!
        deep_symbolize(config_hash)
      rescue StandardError
        raise 'Please ensure your config file is formatted correctly. `sanctum config --help`'
      end

      def deep_symbolize(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), hash|
            hash[k.to_sym] = deep_symbolize(v)
          end
        when Array
          obj.map { |el| deep_symbolize(el) }
        else
          obj
        end
      end
    end
  end
end
