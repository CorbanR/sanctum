# frozen_string_literal: true

require 'sanctum/template/config_file'

module Sanctum
  module Command
    # Intentionally not extending Base
    # This command creates an example config
    class Init
      include Colorizer
      attr_reader :config_path, :contents

      def initialize(options = {})
        options = { working_dir: Pathname.getwd }.merge(options).compact

        @config_path = options.key?(:config) ? Pathname.new(options[:config]) : options[:working_dir] + 'sanctum.yaml'
        @contents = Template::ConfigFile.new.render
      end

      def run
        raise yellow('config file already exists') if config_path.exist?

        create_config_file
      end

      def create_config_file
        File.write(config_path, contents)
      end
    end
  end
end
