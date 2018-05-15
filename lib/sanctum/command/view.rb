require 'yaml'

module Sanctum
  module Command
    class View < Base

      def run(command="less")

        unless args.empty?
          local_secrets = read_local(args)
          unless local_secrets.empty?
            begin
              local_secrets = VaultTransit.decrypt(vault_client, local_secrets, transit_key)
              unless command.nil?
                IO.popen(command, "w") { |f| f.puts "#{local_secrets.to_yaml}" }
              else
                puts light_blue(local_secrets.to_yaml)
              end

            rescue
              puts light_blue(local_secrets.to_yaml)
            end
          end
        end

      end

      def read_local(paths)
        tmp_hash = Hash.new
        paths.each do |k,v|
          if File.file?(k)
            v = File.read(k)
            tmp_hash["#{k}"] = v
          else
            warn red("File #{k} does not exist.")
            next
          end
        end
        tmp_hash
      end

    end
  end
end
