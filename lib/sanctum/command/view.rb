require 'yaml'

module Sanctum
  module Command
    class View < Base

      def run(command="less")
        raise ArgumentError, red('Please provide at least one path') if args.empty?

        local_secrets = read_local_files(args)
        begin
          local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)
          IO.popen(command, "w") { |f| f.puts "#{local_secrets.to_yaml}" }
        rescue
          puts light_blue(local_secrets.to_yaml)
        end
      end

    end
  end
end
