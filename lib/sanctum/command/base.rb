module Sanctum
  module Command
    class Base
      include Colorizer

      attr_reader :options, :args, :transit_key, :apps, :config_file

      def initialize(options={}, args=[])
        @options = options
        @args = args

        if options.kind_of?(Hash)
          @transit_key = options[:vault][:transit_key]
          @apps = options[:sync]
          @config_file = options[:config_file]
        end
      end

      def vault_client
        @vault_client ||= VaultClient.build(options[:vault][:url], options[:vault][:token])
      end

    end
  end
end
