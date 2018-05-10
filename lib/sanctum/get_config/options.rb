require 'etc'
require 'pathname'

module Sanctum
  module GetConfig
    class DefaultOptions
      attr_reader :config_file

      def initialize(config_file=nil)
        @config_file = config_file
      end

      def run
        {
          config_file: config_file.nil? ? config_file_search : config_file,
          sanctum: { force: false, color: true },
          vault: { url: "https://127.0.0.1:8200", token: get_vault_token }
        }
      end

      def config_file_search
        path = Pathname.new(Dir.pwd)
        path.ascend do |p|
          if File.file?("#{p}/sanctum.yaml")
            return "#{p}/sanctum.yaml"
          else
            next
          end
        end
      end

      def get_vault_token
        token_file = "#{Dir.home}/.vault-token"
        if File.file?("#{token_file}") && File.readable?("#{token_file}")
          File.read("#{token_file}")
        end
      end

    end
  end
end
