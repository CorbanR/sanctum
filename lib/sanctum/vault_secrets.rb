module Sanctum
  class VaultSecrets
    include Colorizer
    attr_reader :vault_client, :prefix, :secrets_version

    def initialize(vault_client, prefix, secrets_version="1")
      @vault_client = vault_client
      @prefix = prefix
      @secrets_version = secrets_version
    end

    # API version 2 uses /metadata path to list, but /data to read.
    #TODO Fix, change list_prefix back to prefix at some point. Use new kv from vault-ruby once it's updated
    def get_all
      raise yellow("Warning: Vault prefix: '#{prefix}' does not exist.. ") if invalid_prefix?

      secrets_from_vault = Hash.new
      secrets_from_vault[prefix] = JSON(list_recursive(list_prefix).to_json)
      secrets_from_vault
    end

    private

    # API version 2 uses /metadata path to list, but /data to read.
    # TODO remove method and use kv from vault-ruby once available.
    def list_prefix
      if secrets_version == "2"
        prefix.include?("/data") ? prefix.sub(/data/, "metadata") : "#{prefix}/metadata"
      else
        prefix
      end
    end

    # TODO Fix, change list_prefix back to prefix at some point. Use new kv from vault-ruby once it's updated
    def list_recursive(list_prefix, parent = '')
      me = File.join(parent, list_prefix)
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

    # Used by list_recursive method only
    # API version 2 uses /metadata path to list, but /data to read.
    # TODO Update to use kv from vault-ruby once available.
    def read_data(item, parent = '')
      me = File.join(parent, item)

      # me will contain /metadata if secrets_version 2 due to list_prefix method
      if secrets_version == "2"
        me = me.sub(/metadata/, "data")
        vault_client.logical.read(me).data[:data]
      else
        vault_client.logical.read(me).data
      end
    end

    # API version 2 uses /metadata path to list, but /data to read.
    # TODO Fix, change list_prefix back to prefix at some point. Use new kv from vault-ruby once it's updated
    def invalid_prefix?
      vault_client.logical.list(list_prefix).empty?
    end
  end
end
