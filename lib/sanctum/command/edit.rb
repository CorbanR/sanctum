require 'fileutils'
require 'tempfile'
require 'yaml'
require 'json'

module Sanctum
  module Command
    class Edit < Base

      def run(&block)
        if args.one?
          path = args[0]
          edit_file(path, &block)
        end
      end

      private
      def edit_file(path)
        e = EditorHelper.new
        tmp_file = Tempfile.new(File.basename(path))

        begin
          encrypted_data_hash = {path => File.read(path)}
          decrypted_data_hash = e.decrypt_data(vault_client, encrypted_data_hash, transit_key)
          decrypted_data_hash.each_value do |v|
            v = v.to_yaml
            File.write(tmp_file.path, v)
          end

          if block_given?
            yield tmp_file
          else
            previous_contents = File.read(tmp_file.path)
            editor = ENV.fetch('EDITOR', 'vi')
            raise red("Error with editor") unless system(editor, tmp_file.path )
          end
          contents = File.read(tmp_file.path)

          # Only write contents if something changed
          unless contents == previous_contents
            data_hash = {"#{tmp_file.path}" => e.validate(contents)}
            e.write_encrypted_data(vault_client, data_hash, transit_key)
            tmp_file.close

            FileUtils.cp(tmp_file.path, path)
          end

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
