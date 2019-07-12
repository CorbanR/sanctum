# frozen_string_literal: true

module Sanctum
  module Command
    class Edit < Base
      def run(&block)
        if args.one?
          path = args.first
          transit_key = determine_transit_key(path, targets)
          edit_file(path, transit_key, &block)
        else
          raise ArgumentError, red('Please pass only one path argument')
        end
      end

      private

      def edit_file(path, transit_key)
        tmp_file = Tempfile.new(File.basename(path))

        begin
          encrypted_data_hash = { path => File.read(path) }
          decrypted_data_hash = decrypt_data(vault_client, encrypted_data_hash, transit_key)
          decrypted_data_hash.each_value do |v|
            v = v.to_yaml
            File.write(tmp_file.path, v)
          end

          if block_given?
            yield tmp_file
          else
            previous_contents = File.read(tmp_file.path)
            TTY::Editor.open(tmp_file.path)
          end
          contents = File.read(tmp_file.path)

          # Only write contents if something changed
          unless contents == previous_contents
            data_hash = { tmp_file.path.to_s => validate(contents) }
            write_encrypted_data(vault_client, data_hash, transit_key)
            tmp_file.close

            FileUtils.cp(tmp_file.path, path)
          end
        rescue StandardError => e
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
end
