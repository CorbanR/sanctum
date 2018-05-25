require 'vault'

module Sanctum
  class VaultClient

    def self.build(vault_address, vault_token)
      vault_client = Vault::Client.new(address: vault_address, token: vault_token)
      check_token(vault_client)
      vault_client
    end

    def self.check_token(vault_client)
      response = vault_client.request(:get, "v1/auth/token/lookup-self")
      renewable = response[:data][:renewable]

      if renewable
        creation_ttl = response[:data][:creation_ttl]
        remaining = response[:data][:ttl]
        fifty_percent = (creation_ttl * 0.50).to_i

        renew_token(vault_client, creation_ttl) if remaining < fifty_percent
      end
    end

    def self.renew_token(vault_client, increment)
      payload = {"increment": increment}.to_json
      vault_client.request(:post, "v1/auth/token/renew-self", payload)
    end

  end
end
