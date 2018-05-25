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
        @targets = options.fetch(:sync)
        @config_file = options.fetch(:config_file)
      end

      def vault_client
        @vault_client ||= VaultClient.build(options[:vault][:url], options[:vault][:token])
      end

    end
  end
end
