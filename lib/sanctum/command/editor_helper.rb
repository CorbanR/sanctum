require 'securerandom'
require 'yaml'
require 'json'

module Sanctum
  module Command
    class EditorHelper

      def decrypt_data(vault_client, data, transit_key)
        VaultTransit.decrypt(vault_client, data, transit_key)
      end

      def write_encrypted_data(vault_client, data, transit_key)
        VaultTransit.write_to_file(vault_client, data, transit_key)
      end

      def valid?(contents)
        valid_json?(contents) or valid_yaml?(contents)
      end

      def valid_json?(json)
        JSON.parse(json)
        return true
      rescue JSON::ParserError => e
        e.message
        return false
      end

      #TODO is there a better way to do this?
      def valid_yaml?(yaml)
        return true if YAML.load(yaml)
      rescue YAML::SyntaxError => e
        e.message
        return false
      end

      #TODO: research this a bit more.. to ensure this is sufficient
      def write_random_data(file, file_len)
        max_chunk_len = [file_len, (1024 * 1024 * 2)].max

        3.times do
          random_data = SecureRandom.random_bytes(max_chunk_len)
          File.write(file, random_data, 0, mode: 'wb')
        end
      end

      def secure_erase(file, file_len)
        if file_len >= 1
          begin
            #Try to use shred if available on system
            raise red("Failed system shred") unless system("shred", file)
          rescue
            write_random_data(file, file_len)
          end
        end
      end

    end
  end
end
