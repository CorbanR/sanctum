require "pathname"

module Sanctum
  module Command
    class Update < Base
      def run
        raise red("Please only specify one target") if targets.count > 1
        target = targets.first

        # Use command line if force: true
        if options[:cli][:force]
          force = options[:cli][:force]
        else
          force = target.fetch(:force) {options[:sanctum][:force]}
        end

        update_mount(target, force)
      end

      private

      def update_mount(target, force)
        data = { options: { version: "2" }, listing_visability: "unauth" }.to_json
        pre_upgrade_warning

        if force
          # When force option is used we will try to run the upgrade command mount, even if it's already been upgraded
          # Request will be a no-op and return null. So we need to remove `data` from the prefix if it's been added.
          force_prefix = target[:prefix].include?("/data") ? target[:prefix].sub(/\/data/, "") : target[:prefix]
          warn yellow("\nUpgrading #{force_prefix}")
          upgrade_response = vault_client.request(:post, "/v1/sys/mounts/#{force_prefix}/tune", data)
        else
          already_upgraded_warning if target[:secrets_version] == "2"
          upgrade_response = confirm_upgrade?(target) ? vault_client.request(:post, "/v1/sys/mounts/#{target[:prefix]}/tune", data) : nil
        end
        upgrade_response.nil? ? nothing_happened_warning : (warn yellow("#{upgrade_response}\n#{post_upgrade_warning}"))

        post_upgrade_tasks(target)
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
          "Request returned a nil response, which could mean mount is already upgraded"
        )
      end

      def confirm_upgrade?(target)
        warn yellow("\nUpgrading will make the mount temporarily unavailable")
        warn red("\nPlease ensure you are fully synced(all secrets have been pushed/pulled)")
        warn yellow("Would you like to continue?: ")
        question = STDIN.gets.chomp.upcase

        if ["Y", "YES"].include? question
          warn yellow("\nUpgrading #{target[:prefix]}")
          true
        else
          raise yellow("\nSkipping....\n")
          false
        end
      end

      # Post upgrade tasks if mount is being upgraded from generic mount or v1 mount to v2 mount
      # Ensure local files mimic vault v2 by add `/data` to local path
      def post_upgrade_tasks(target)
        config_path = Pathname.new(config_file).dirname.to_s
        full_target_path = "#{config_path}/#{target[:path]}"

        old_path = full_target_path.include?("/data") ? full_target_path.sub(/\/data/, "") : full_target_path
        new_path = full_target_path.include?("/data") ? full_target_path : "#{full_target_path}/data"

        # If old path does not exist, chances are sanctum upgrade is being run before sanctum pull/push.
        return unless File.directory?(old_path)

        files_to_move = Dir.chdir(old_path) { Dir.glob('*') }.delete_if {|i| i == "data"}
        unless files_to_move.empty?
          FileUtils.mkdir_p(new_path) unless File.directory?(new_path)
          files_to_move.each do |f|
            FileUtils.mv("#{old_path}/#{f}", new_path, secure: true)
          end
        end
      rescue
        warn red("Post upgrade tasks failed")
        raise
      end
    end
  end
end
