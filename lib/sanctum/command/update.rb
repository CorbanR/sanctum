require "pathname"

module Sanctum
  module Command
    class Update < Base
      def run
        targets.each do |target|
          # Use command line if force: true
          if options[:cli][:force]
            force = options[:cli][:force]
          else
            force = target.fetch(:force) {options[:sanctum][:force]}
          end

          update_mount(target, force)

        end
      end

      private

      def update_mount(target, force)
        data = { options: { version: "2" }, listing_visability: "unauth" }.to_json
        pre_upgrade_warning

        if force
          warn yellow("\nUpgrading #{target[:prefix]}")
          upgrade_response = vault_client.request(:post, "/v1/sys/mounts/#{target[:prefix]}/tune", data)
          upgrade_response.nil? ? nothing_happened_warning : (warn yellow("#{upgrade_response}"))
        else
          already_upgraded_warning if target[:secrets_version] == "2"
          warn yellow("#{vault_client.request(:post, "/v1/sys/mounts/#{target[:prefix]}/tune", data)}") if confirm_upgrade?(target)
        end
        post_upgrade_warning(target)
      end

      def pre_upgrade_warning
        warn yellow(
          "\nPlease read 'Upgrading from Version 1' documentation BEFORE you upgrade"\
          "\nThe addition of `/data`, and `/metadata` endpoints will break applications that are depending on v1 endpoints"\
          "\nYou will want to update permissions policies, and applications BEFORE you upgrade"\
          "\nhttps://www.vaultproject.io/docs/secrets/kv/kv-v2.html#upgrading-from-version-1"\
        )
        additional_acl_warning
      end

      def post_upgrade_warning(target)
        warn yellow(
          "\nOnce the upgrade has been completed, make sure you update your sanctum.yaml."\
          "\nPlease add the `secrets_version: 2` key to the #{target[:prefix]} config."
        )
      end

      def additional_acl_warning
        warn yellow(
          "\nIf you use policies to limit secrets access you may need to have your permissions updated"\
          "\nSee https://www.vaultproject.io/docs/secrets/kv/kv-v2.html#acl-rules for more info"\
          "\nSpecifically you may need add something similar to the following:"\
          "\npath \"<secrets_mount>/data/*\" { capabilities = [\"list\",\"read\",\"create\",\"update\",\"delete\"] }"\
          "\npath \"<secrets_mount>/metadata/*\" { capabilities = [\"list\",\"read\",\"create\",\"update\",\"delete\"] }"\
          "\npath \"<secrets_mount>/destroy/*\" { capabilities = [\"update\"] }"\
          "\npath \"<secrets_mount>/delete/*\" { capabilities = [\"update\"] }"\
          "\npath \"<secrets_mount>/undelete/*\" { capabilities = [\"update\"] }"
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
          "Request was successfull but returned a nil response, this generally means the mount has is already upgraded!"
        )
      end

      def confirm_upgrade?(target)
        warn yellow("\nUpgrading will make the mount temporarily unavailable")
        warn yellow("Would you like to continue?: ")
        question = STDIN.gets.chomp.upcase

        if ["Y", "YES"].include? question
          warn yellow("\nUpgrading #{target[:prefix]}")
          true
        else
          warn yellow("\nSkipping....\n")
          false
        end
      end
    end
  end
end
