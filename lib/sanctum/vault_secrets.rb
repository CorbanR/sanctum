module Sanctum
  class VaultSecrets
    include Colorizer

    def self.get(vault_client, prefix)
      if invalid_prefix?(vault_client, prefix)
        raise yellow("Warning: Vault prefix: '#{prefix}' does not exist.. ")
      end

      @secrets_from_vault = Hash.new
      @secrets_from_vault[prefix] = JSON(list_recursive(vault_client, prefix).to_json)
      @secrets_from_vault
    end

    def self.invalid_prefix?(vault_client, prefix)
      vault_client.logical.list(prefix).empty?
    end

    def self.list_recursive(vault, path, parent = '')
      me = File.join(parent, path)
      result = vault.logical.list(me).inject({}) do |hash, item|
        case item
        when /.*\/$/
          hash[item.gsub(/\/$/, '').to_sym] = list_recursive(vault, item, me)
        else
          hash[item.to_sym] = read_data(vault, item, me)
        end
        hash
      end
      result
    end

    def self.read_data(vault, item, parent = '')
      me = File.join(parent, item)
      vault.logical.read(me).data
    end

  end
end
