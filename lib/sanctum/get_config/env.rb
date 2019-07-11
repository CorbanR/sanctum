# frozen_string_literal: true

module Sanctum
  module GetConfig
    class Env
      attr_reader :env_options

      def initialize
        @env_options = { vault: { url: ENV['VAULT_ADDR'], token: ENV['VAULT_TOKEN'] } }
      end

      def run
        env_options.each do |_key, value|
          value.compact!
        end
      end
    end
  end
end
