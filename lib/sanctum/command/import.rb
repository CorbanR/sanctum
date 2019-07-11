# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'yaml'
require 'json'

module Sanctum
  module Command
    class Import < Base
      def run
        if args.count != '2'
          source_path, dest_path = args
          transit_key = determine_transit_key(dest_path, targets)

          force = options[:cli][:force] if options[:cli][:force]

          import_file(source_path, dest_path, transit_key, force)
        else
          raise ArgumentError, red('Please pass the path to both the source and the destination file')
        end
      end

      private

      def import_file(source_path, dest_path, transit_key, force = nil)
        tmp_file = Tempfile.new(File.basename(source_path))
        FileUtils.cp(source_path, tmp_file)

        previous_contents = File.read(tmp_file.path)
        TTY::Editor.open(tmp_file.path) unless force
        contents = File.read(tmp_file.path)

        # Encrypt the data
        data_hash = { tmp_file.path.to_s => validate(contents) }
        write_encrypted_data(vault_client, data_hash, transit_key)
        tmp_file.close

        FileUtils.cp(tmp_file.path, dest_path)
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
  end
end
