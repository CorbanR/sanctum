require 'fileutils'

module Sanctum
  module Command
    class Config
      include Colorizer

      attr_reader :config_file, :example_file
      def initialize
        working_dir = Dir.pwd
        relative_path = File.expand_path File.dirname(__FILE__)
        @config_file = "#{working_dir}/sanctum.yaml"
        @example_file = "#{relative_path}/sanctum.example.yaml"
      end

      def run
        raise yellow("config file already exists") if config_exist?(config_file)
        create_config_file(example_file, config_file)
      end

      def config_exist?(config_file)
        File.file?(config_file)
      end

      def create_config_file(example_file, config_file)
        FileUtils.cp(example_file, config_file)
      end

    end
  end
end
