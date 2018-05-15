require 'fileutils'

module Sanctum
  module Command
    class Config < Base

      attr_reader :config_path, :example_file

      def initialize(working_dir=Dir.pwd)
        relative_path = File.expand_path File.dirname(__FILE__)
        @config_path = "#{working_dir}/sanctum.yaml"
        @example_file = "#{relative_path}/sanctum.example.yaml"
        super
      end

      def run
        raise yellow("config file already exists") if config_exist?
        create_config_file
      end

      def config_exist?
        File.file?(config_path)
      end

      def create_config_file
        FileUtils.cp(example_file, config_path)
      end

    end
  end
end
