# frozen_string_literal: true

require 'yaml'

module Sanctum
  module Command
    class View < Base
      def run(command = 'less')
        if args.one?
          path = args.first
          transit_key = determine_transit_key(path, targets)
        else
          raise ArgumentError, red('Please pass only one path argument')
        end

        # TODO: Fix later, expects an array of paths
        local_secrets = read_local_files([path.to_s])
        local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)
        begin
          IO.popen(command, 'w') { |f| f.puts local_secrets.to_yaml.to_s }
        rescue StandardError
          puts light_blue(local_secrets.to_yaml)
        end
      end
    end
  end
end
