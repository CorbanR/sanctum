require 'fileutils'
require 'tempfile'
require 'yaml'
require 'json'

module Sanctum
  module Command
    class Create
      include Colorizer
      attr_reader :options, :args

      def initialize(options, args)
        @options = options
        @args = args
      end

      def run(&block)
        vault_client = VaultClient.new(options[:vault][:url], options[:vault][:token]).vault_client
        target = options[:cli][:targets]
        transit_key = options[:vault][:transit_key]

        unless target.nil?
          app = options[:sync].find {|x| x[:name] == "#{target[0]}"}
          transit_key = app[:transit_key] if app.has_key?(:transit_key)
        end

        if args.length == 1
          path = args[0]
          if File.exist?(path)
            raise yellow("File exists, use edit command")
          end
          create_file(path, vault_client, transit_key, &block)
        end

      end

      private
      def create_file(path, vault_client, transit_key)
        e = EditorHelper.new
        editor = ENV['EDITOR']
        tmp_file = Tempfile.new(File.basename(path))

        begin
          if block_given?
            yield tmp_file
          else
            raise red("Error with editor") unless system(editor, tmp_file.path)
          end

          contents = File.read(tmp_file.path)

          if e.valid?(contents)
            #TODO: Figure out a better way to very yaml...
            data_hash = {"#{tmp_file.path}" => JSON.parse(contents)} if e.valid_json?(contents)
            data_hash = {"#{tmp_file.path}" => YAML.load(contents,{})} if e.valid_yaml?(contents)

            e.write_encrypted_data(vault_client, data_hash, transit_key)
            tmp_file.close

            FileUtils.cp(tmp_file.path, path)
          else
            raise red("Please ensure contents are valid json or yaml")
          end
        ensure
          tmp_file.close
          e.secure_erase(tmp_file.path, tmp_file.length)
          tmp_file.unlink
        end
      end

    end
  end
end
