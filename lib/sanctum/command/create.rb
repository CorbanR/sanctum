require 'fileutils'
require 'json'
require 'pathname'
require 'tempfile'
require 'yaml'

module Sanctum
  module Command
    class Create < Base

      def run(&block)
        if args.one?
          path = args[0]
          validate_path(path)
          create_file(path, &block)
        else
          raise ArgumentError, red('Please pass only one path argument')
        end
      end

      private
      def create_file(path)
        # Calling vault_client will help prevent a race condition where the token is expired
        # and contents fail to encrypt
        vault_client
        tmp_file = Tempfile.new(File.basename(path))

        begin
          if block_given?
            yield tmp_file
          else
            editor = ENV.fetch('EDITOR', 'vi')
            raise red("Error with editor") unless system(editor, tmp_file.path)
          end

          contents = File.read(tmp_file.path)
          data_hash = {"#{tmp_file.path}" => validate(contents)}
          write_encrypted_data(vault_client, data_hash, transit_key)
          tmp_file.close

          FileUtils.cp(tmp_file.path, path)
        rescue Exception => e
          # If write_encrypted_data failed, data would fail to write to disk
          # It would be sad to lose that data, at least this would print the contents to the console.
          puts red("Contents may have failed to write\nError: #{e}")
          puts yellow("Contents: \n#{contents}")
        ensure
          tmp_file.close
          secure_erase(tmp_file.path, tmp_file.length)
          tmp_file.unlink
        end
      end

      # Check if the path you are creating matches a target path
      # if secrets_version == 2 /data will be added to the path
      # See command/base.rb
      def path_matches_a_target?(path)
        targets.each do |h|
          path.to_s.include?(h[:path]) ? (return true) : (return false)
        end
      end

      def validate_path(path)
        path = Pathname.new(path)
        keys_to_print = targets.map { |h| h.slice(:name, :path) }
        raise yellow("File exists, use edit command") if path.exist?
        raise yellow("No targets contain a :path key that matches the path you specified\n#{keys_to_print}") unless path_matches_a_target?(path)

        path.dirname.mkpath unless path.dirname.exist?
      end

    end
  end
end
