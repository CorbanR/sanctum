# frozen_string_literal: true

require 'erb'

module Sanctum
  module Templates
    # TODO: Update template to use calculated default config(via config class)
    #
    # Using erb, render example sanctum.yaml
    class Init
      attr_reader :template

      def initialize
        # rubocop:disable Style/UnneededPercentQ
        @template = %q{
---
sanctum:
  # color - defaults to true. Setting to false will disable color to tty
  #color: true
  # force - defaults to false. Setting to true modifies behavior of push and pull commands.
  #   If true you will not be asked if you want to overwrite changes. Can be overridden on a per target basis.
  #force: false
  # secrets_version - defaults to `auto`, which will try to automatically detect secrets_version
  #   can be overridden on a per target basis
  #secrets_version: auto
  # transit_key - (required if not set ) default transit_key to be used, can be overridden on a per target basis
  #   Transit key ring used to encrypt/decrypt secrets for local storage.
  #   If you need to use multiple transit_keys you will need to create seperate config files
  #transit_key: transit/keys/app-foo

vault:
  # url - will use `ENV["VAULT_ADDR"]` if available, otherwise defaults to http://localhost:8200
  #url: http://localhost:8200
  # token - (required) will use `ENV["VAULT_TOKEN"]` if available, otherwise tries to read from `ENV["HOME"]/.vault-token`
  #token: aaabbbcc-ddee-ffgg-hhii-jjkkllmmnnoop

sync:
  # sync is an array of hashes of sync target configurations
  # at least one app definition is REQUIRED
  # Fields:
  #     name - (required) Friendly name of the sync target.
  #     prefix - (required) The vault prefix(secret mount) to synchronize to.
  #     path - (required) The relative filesystem path that gets synchronized
  #       with Vault. This path is calculated relative to the directory containing
  #       the sanctum configuration file.
  #     force - Whether or not to force push, pull actions (no user input)
  #       Inherits the setting from the `sanctum` section.
  #     secrets_version - The k/v secrets version `1`, or `2`. Sanctum will try to detect this automatically
  #       if not valued. Inherits the setting from the `sanctum` section.
  #     transit_key - (required if not set in `sanctum` section) Transit key ring used to encrypt/decrypt secrets
  #     for local storage. Inherits the setting from the `sanctum` section.
  #- name: app-foo
    #prefix: secrets/app-foo
    #path: vault/app-foo
    #force: false
  #- name: app-bar
    #prefix: app-bar
    #path: vault/app-bar
    #transit_key: transit/keys/app-bar
    #secrets_version: 2
    #force: false
  # Example shows if you need to specify multiple nested prefixs
  # You will want to namespace the local `path`
  #- name: app-baz-micro
    #prefix: app-baz/prod/micro
    #path: vault/app-baz-micro/prod/micro
    #transit_key: transit/keys/app-baz-micro
    #secrets_version: 2
    #force: false
  #- name: app-baz-all
    #prefix: app-baz
    #path: vault/app-baz-all/prod/micro
    #transit_key: transit/keys/app-baz-all
    #secrets_version: 2
    #force: false
        }.strip
        # rubocop:enable Style/UnneededPercentQ
      end

      def render
        ERB.new(template, trim_mode: '%<>').result
      end
    end
  end
end
