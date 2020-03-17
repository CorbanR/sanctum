# frozen_string_literal: true

require 'securerandom'
require 'tty-editor'

module Sanctum
  module Command
    module EditorHelper
      include Colorizer

      def decrypt_data(vault_client, data, transit_key)
        Adapter::Vault::Transit.decrypt(vault_client, data, transit_key)
      end

      def write_encrypted_data(vault_client, data, transit_key)
        Adapter::Vault::Transit.write_to_file(vault_client, data, transit_key)
      end

      def validate(contents)
        validate_json(contents) || validate_yaml(contents) || raise
      rescue StandardError
        raise red('Invalid Contents. Must be valid, json or yaml, in key/value pair format')
      end

      def validate_json(json)
        json = JSON.parse(json)
        raise TypeError, 'Data must be in key/value format' unless json.is_a? Hash

        json
      rescue JSON::ParserError, TypeError
        nil
      end

      def validate_yaml(yaml)
        yaml = YAML.safe_load(yaml)
        raise TypeError, 'Data must be in key/value format' unless yaml.is_a? Hash

        yaml
      rescue YAML::SyntaxError
        nil
      end

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
            # Try to use shred if available on system
            raise red('Failed system shred') unless system('shred', file)
          rescue StandardError
            write_random_data(file, file_len)
          end
        end
      end

      # TODO: Don't like this.. need to figure out a better way.
      # Maybe require uses to specify the target when `create, update, or edit?`
      def determine_transit_key(path, targets)
        targets = if targets.count > 1
                    targets.select do |h|
                      path.to_s.include?(h[:path])
                    end
                  else
                    targets
                  end

        error_message = 'Unable to determine transit_key to use, please specify target via `-t <target>`'
        targets.empty? ? (raise error_message) : targets.first[:transit_key]
      end
    end
  end
end
