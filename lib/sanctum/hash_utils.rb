# frozen_string_literal: true

module Sanctum
  # Helpful hash refineries
  module HashUtils
    refine ::Hash do
      def deep_compact
        deep_compact!(deep_dup)
      end

      def deep_compact!(obj = self)
        return unless obj.is_a?(Hash)

        obj.tap do |o|
          o = o.delete_if { |_k, v| v.nil? }
          o.keys.each do |key|
            deep_compact!(o[key])
          end
        end
      end
    end
  end
end
