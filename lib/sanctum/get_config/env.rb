module Sanctum
  module GetConfig
    class Env
      attr_reader :env_options

      def initialize
        @env_options = {vault: {url: ENV["VAULT_ADDR"], token: ENV["VAULT_TOKEN"], transit_key: ENV["VAULT_TRANSIT_KEY"]}}
      end

      def run
        env_options.each do |key, value|
          value.compact!
        end
      end

    end
  end
end
