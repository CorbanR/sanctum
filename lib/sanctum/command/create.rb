require 'fileutils'
require 'tempfile'
require 'yaml'
require 'json'

module Sanctum
  module Command
    class Create < Base

      def run(&block)
        if args.one?
          path = args[0]
          if File.exist?(path)
            raise yellow("File exists, use edit command")
          end
          create_file(path, &block)
        end

      end

      private
      def create_file(path)
        e = EditorHelper.new
        tmp_file = Tempfile.new(File.basename(path))

        begin
          if block_given?
            yield tmp_file
          else
            editor = ENV.fetch('EDITOR', 'vi')
            raise red("Error with editor") unless system(editor, tmp_file.path)
          end

          contents = File.read(tmp_file.path)
          data_hash = {"#{tmp_file.path}" => e.validate(contents)}
          e.write_encrypted_data(vault_client, data_hash, transit_key)
          tmp_file.close

          FileUtils.cp(tmp_file.path, path)
        rescue
          # If e.write_encrypted_data failed, data would fail to write to disk
          # It would be sad to lose that data, at least this would print the contents to the console.
          puts red("Contents may have failed to write")
          puts red(contents)
        ensure
          tmp_file.close
          e.secure_erase(tmp_file.path, tmp_file.length)
          tmp_file.unlink
        end
      end

    end
  end
end
