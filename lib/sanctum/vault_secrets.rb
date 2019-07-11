# frozen_string_literal: true

module Sanctum
  #:nodoc:
  class VaultSecrets
    include Colorizer
    attr_reader :vault_client, :prefix, :secrets_version

    def initialize(vault_client, prefix, secrets_version = '1')
      @vault_client = vault_client
      @prefix = prefix
      @secrets_version = secrets_version
    end

    # API version 2 uses /metadata path to list, but /data to read.
    # TODO Fix, change list_prefix back to prefix at some point. Use new kv from vault-ruby once it's updated
    def get_all # rubocop:disable Naming/AccessorMethodName
      if invalid_prefix?
        raise yellow(
          "Vault prefix: '#{prefix}' does not exist, or doesn't contain any secrets to pull/check"\
          "\nEnsure mount is enabled and use `sanctum create`, and `sanctum push` to add secrets"
        )
      end

      secrets_from_vault = {}
      secrets_from_vault[prefix] = JSON(list_recursive(list_prefix).to_json)
      secrets_from_vault
    end

    private

    # API version 2 uses /metadata path to list, but /data to read.
    # TODO remove method and use kv from vault-ruby once available.
    def list_prefix
      if secrets_version == '2'
        prefix.include?('/data') ? prefix.sub(%r{data}, 'metadata') : "#{prefix}/metadata"
      else
        prefix
      end
    end

    # TODO: Fix, change list_prefix back to prefix at some point.
    # Use new kv from vault-ruby once it's updated.
    # Additionally appease rubocop better
    # rubocop:disable all
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
    # rubocop:enable all

    # Used by list_recursive method only
    # API version 2 uses /metadata path to list, but /data to read.
    # TODO Update to use kv from vault-ruby once available.
    def read_data(item, parent = '')
      me = File.join(parent, item)

      # me will contain /metadata if secrets_version 2 due to list_prefix method
      if secrets_version == '2'
        me = me.sub(%r{metadata}, 'data')
        # It's possible for a vault secret to be nil...
        if vault_client.logical.read(me).nil?
          warn red("vault secret '#{me}' contains a null vaule, ignoring...")
          {}
        else
          vault_client.logical.read(me).data[:data]
        end
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
