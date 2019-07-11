# frozen_string_literal: true

require 'find'
require 'pathname'

module Sanctum
  module Command
    module PathsHelper
      # Helper methods for building, reading and joining paths

      private

      def build_path_helper(hash, path = [])
        if hash.values.any? { |k| !k.is_a?(Hash) }
          [path, hash]
        else
          hash.flat_map do |(key, value)|
            build_path_helper(value, path + [key])
          end
        end
      end

      public

      def build_path(hash, path = [])
        build_path_helper(hash, path).each_slice(2).to_h
      end

      def join_path(hash, config_file)
        config_file = Pathname.new(config_file)
        tmp_hash = {}

        hash.each do |p, v|
          p = config_file.dirname + Pathname.new(p.join('/'))
          tmp_hash[p.to_s] = v
        end
        tmp_hash
      end

      def read_local_files(paths)
        tmp_hash = {}
        paths.each do |k, v|
          if File.file?(k)
            v = File.read(k)
            tmp_hash[k.to_s] = v
          end
        end
        tmp_hash
      end

      def get_local_paths(paths)
        tmp_array = []
        Find.find(paths) do |path|
          next unless FileTest.file?(path)

          tmp_array << path
          if File.basename(path).start_with?('.')
            Find.prune
          else
            next
          end
        end
        tmp_array
      end
    end
  end
end
