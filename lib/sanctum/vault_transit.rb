# frozen_string_literal: true

require 'base64'

module Sanctum
  #:nodoc:
  class VaultTransit
    extend Colorizer

    def self.encrypt(vault_client, secrets, transit_key)
      transit_key = Pathname.new(transit_key)

      # TODO: probably nice to do this check earlier on,
      # Such as in command/base
      unless transit_key_exist?(vault_client, transit_key)
        raise red("transit_key: #{transit_key.inspect}, does not exist")
      end

      secrets.each do |k, v|
        v = encode(v.to_json)
        # TODO: Fix this....
        v = vault_client.logical.write(
          "#{transit_key.dirname.to_s.split('/')[0]}/encrypt/#{transit_key.basename}",
          plaintext: v
        )
        secrets[k] = v
      end
      secrets
    end

    def self.decrypt(vault_client, secrets, transit_key)
      transit_key = Pathname.new(transit_key)
      secrets.each do |k, v|
        v = vault_client.logical.write(
          "#{transit_key.dirname.to_s.split('/')[0]}/decrypt/#{transit_key.basename}",
          ciphertext: v
        )
        v = JSON(decode(v.data[:plaintext]))
        secrets[k] = v
      end
      secrets
    end

    # Writes secrets encrypted with transit to local files
    #
    # @param vault_client [VaultClient] client used interact with the vault api
    # @param secrets [hash] {"/local/path": {key: value}}
    # @param transit_key [String] key used to encrypt blobs via the transit backend
    def self.write_to_file(vault_client, secrets, transit_key)
      # Coerce vault data values to strings
      # To ensure a consistent experience pulling and pushing to vault
      secrets.each { |_, v| v.transform_values!(&:to_s) }
      secrets = encrypt(vault_client, secrets, transit_key)
      secrets.each do |k, v|
        create_path(k)
        File.write(k, v.data[:ciphertext])
      end
    end

    # Writes secrets to vault
    #
    # @param vault_client [VaultClient] client used to interact with the vault api
    # @param secrets [hash] {"/vault/path": {key: value}}
    # @param secrets_version [String] vault backend version[1, 2]
    def self.write_to_vault(vault_client, secrets, secrets_version = '1')
      secrets.each do |k, v|
        # Coerce vault data values to strings
        # To ensure a consistent experience pulling and pushing to vault
        v.transform_values!(&:to_s)
        secrets_version == '2' ? vault_client.logical.write(k, data: v) : vault_client.logical.write(k, v)
      end
    end

    def self.encode(string)
      Base64.encode64(string)
    end

    def self.decode(string)
      Base64.decode64(string)
    end

    def self.transit_key_exist?(vault_client, transit_key)
      !vault_client.logical.read(transit_key.to_path).nil?
    end

    def self.create_path(path)
      path = Pathname.new(path).parent.to_path
      FileUtils.mkdir_p(path) unless File.directory?(path)
    end
  end
end
