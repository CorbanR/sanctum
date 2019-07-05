# frozen_string_literal: true

require 'fileutils'

module Sanctum
  module Command
    # Intentionally not extending Base
    # This command creates an example config
    class Config
      include Colorizer
      attr_reader :config_path, :example_file

      def initialize(options = {}, _args = [])
        options = { working_dir: Dir.pwd }.merge(options)

        relative_path = File.expand_path(__dir__)
        @config_path = "#{options[:working_dir]}/sanctum.yaml"
        @example_file = "#{relative_path}/sanctum.example.yaml"
      end

      def run
        raise yellow('config file already exists') if config_exist?

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
