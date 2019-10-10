# frozen_string_literal: true

require 'erb'

module Sanctum
  module Templates
    # Using erb, render example sanctum.yaml
    class ConfigFile
      def initialize
        @default_options = Config::Default.new.options
      end

      def template
        # rubocop:disable Style/UnneededPercentQ
        %q{
---
sanctum:
  ## Toggle color in the termal(ttl)
  #color: <%= @default_options.dig(:sanctum, :color) %>
  ## Toggle user validation for sync commands(setting to true skips user validation)
  #force: <%= @default_options.dig(:sanctum, :force) %>

vault:
  ## Vault endpoint. Will use `ENV["VAULT_ADDR"]` if available
  #addr: <%= @default_options.dig(:vault, :addr) %>
  ## Vault token. Will use `ENV["VAULT_TOKEN"]` if available, otherwise tries to read from `ENV["HOME"]/.vault-token` (Required)
  #token: <my_token>
  ## Vault secret mounts version. Valid values are 1, 2, or auto.
  #secrets_version: <%= @default_options.dig(:vault, :secrets_version) %>
  ## Key used to encrypt secrets. (Required (here or on a per target basis))
  #transit_key: transit/keys/<my_key>

sync:
  ## sync is an array of hashes of sync target configurations
  ## at least one app definition is REQUIRED
  ## Fields:
  ##     name - Friendly name of the sync target. (Required)
  ##     prefix - The vault prefix(secret mount) to synchronize to. (Required)
  ##     path - The relative filesystem path that gets synchronized.
  ##       with Vault. This path is calculated relative to the directory containing
  ##       the sanctum configuration file. (Required)
  ##     vault - Override default vault: config per target(Optional(see above vault section for values to override))
  #- name: app-foo
    #prefix: secrets/app-foo
    #path: vault/app-foo
  #- name: app-bar
    #prefix: app-bar
    #path: vault/app-bar
    #vault:
      #transit_key: transit/keys/app-bar
      #secrets_version: 2
  # Example shows if you need to specify multiple nested prefixs
  # You will want to namespace the local `path`
  #- name: app-baz-prod
    #prefix: app-baz/prod
    #path: vault/app-baz-prod/prod
    #vault:
      #transit_key: transit/keys/app-baz-prod
      #secrets_version: 2
  #- name: app-baz-dev
    #prefix: app-baz/dev
    #path: vault/app-baz-dev/dev
    #vault:
      #transit_key: transit/keys/app-baz-dev
      #secrets_version: 2
        }.strip
        # rubocop:enable Style/UnneededPercentQ
      end

      def render
        ERB.new(template, trim_mode: '%<>').result(binding)
      end
    end
  end
end
