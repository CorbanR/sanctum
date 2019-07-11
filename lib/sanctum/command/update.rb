# frozen_string_literal: true

require 'pathname'

module Sanctum
  module Command
    class Update < Base
      def run
        raise red('Please only specify one target') if targets.count > 1

        target = targets.first

        # Use command line if force: true
        force = options[:cli][:force] || target.fetch(:force) { options[:sanctum][:force] }

        update_mount(target, force)
      end

      private

      def update_mount(target, force)
        data = { options: { version: '2' }, listing_visability: 'unauth' }.to_json
        pre_upgrade_warning

        if force
          # When force option is used we will try to run the upgrade command mount, even if it's already been upgraded
          # Request will be a no-op and return null. So we need to remove `data` from the prefix if it's been added.
          force_prefix = target[:prefix].include?('/data') ? target[:prefix].sub(%r{/data}, '') : target[:prefix]
          warn yellow("\nUpgrading #{force_prefix}")
          upgrade_response = vault_client.request(:post, "/v1/sys/mounts/#{force_prefix}/tune", data)
        else
          already_upgraded_warning if target[:secrets_version] == '2'
          upgrade_response = confirm_upgrade?(target) ? vault_client.request(:post, "/v1/sys/mounts/#{target[:prefix]}/tune", data) : nil
        end
        upgrade_response.nil? ? nothing_happened_warning : (warn yellow("#{upgrade_response}\n#{post_upgrade_warning}"))
      end

      def pre_upgrade_warning
        warn yellow(
          "\nPlease read 'Upgrading from Version 1' documentation BEFORE you upgrade"\
          "\nThe addition of `/data`, and `/metadata` endpoints will break applications that are dependant on v1 endpoints"\
          "\nYou will want to update permissions policies, and applications BEFORE you upgrade"\
          "\nhttps://www.vaultproject.io/docs/secrets/kv/kv-v2.html#upgrading-from-version-1"\
        )
        additional_acl_warning
      end

      def post_upgrade_warning
        warn yellow(
          "\nOnce the upgrade has been completed update sanctum.yaml."\
          "\nPlease add or update `secrets_version:` key to each configured target."\
        )
      end

      def additional_acl_warning
        warn yellow(
          "\nIf you use policies to limit secrets access you may need to have your permissions updated"\
          "\nSee https://www.vaultproject.io/docs/secrets/kv/kv-v2.html#acl-rules for more info"\
          "\nSee examples/single_target for updated policy example."\
        )
      end

      def already_upgraded_warning
        raise red(
          "Mount appears to have already been updated. This could be due to `secrets_version: 2` specified"\
          "\nin sanctum.yaml, or the mount having already been upgraded."\
          "\nTo try anyway you can pass `--force` on the command line"
        )
      end

      def nothing_happened_warning
        warn yellow(
          'Request returned a nil response, which could mean mount is already upgraded'
        )
      end

      def confirm_upgrade?(target)
        warn yellow("\nUpgrading will make the mount temporarily unavailable")
        warn red("\nPlease ensure you are fully synced(all secrets have been pushed/pulled)")
        warn yellow('Would you like to continue?: ')
        question = STDIN.gets.chomp.upcase

        if %w[Y YES].include? question
          warn yellow("\nUpgrading #{target[:prefix]}")
          true
        else
          raise yellow("\nSkipping....\n")
          false
        end
      end
    end
  end
end
