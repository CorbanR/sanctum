require 'vault'

module Sanctum
  class VaultClient
    attr_reader :vault_client

    def initialize(vault_address, vault_token)
      @vault_client = Vault::Client.new(address: vault_address, token: vault_token)
      check_token
    end

    def check_token
      response = vault_client.request(:get, "v1/auth/token/lookup-self")
      renewable = response[:data][:renewable]

      if renewable
        creation_ttl = response[:data][:creation_ttl]
        remaining = response[:data][:ttl]
        thirty_percent = (creation_ttl * 0.30).to_i

        renew_token(creation_ttl) if remaining < thirty_percent
      end
    rescue => e
      raise e
    end

    def renew_token(increment)
      payload = {"increment": increment}.to_json
      vault_client.request(:post, "v1/auth/token/renew-self", payload)
    rescue => e
      raise e
    end

  end
end
