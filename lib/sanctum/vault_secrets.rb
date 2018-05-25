module Sanctum
  class VaultSecrets
    include Colorizer
    attr_reader :vault_client, :prefix

    def initialize(vault_client, prefix)
      @vault_client = vault_client
      @prefix = prefix
    end

    def get
      if invalid_prefix?
        raise yellow("Warning: Vault prefix: '#{prefix}' does not exist.. ")
      end

      secrets_from_vault = Hash.new
      secrets_from_vault[prefix] = JSON(list_recursive(prefix).to_json)
      secrets_from_vault
    end

    private
    def list_recursive(prefix, parent = '')
      me = File.join(parent, prefix)
      result = vault_client.logical.list(me).inject({}) do |hash, item|
        case item
        when /.*\/$/
          hash[item.gsub(/\/$/, '').to_sym] = list_recursive(item, me)
        else
          hash[item.to_sym] = read_data(item, me)
        end
        hash
      end
      result
    end

    def read_data(item, parent = '')
      me = File.join(parent, item)
      vault_client.logical.read(me).data
    end

    def invalid_prefix?
      vault_client.logical.list(prefix).empty?
    end

  end
end
