module Sanctum
  module GetConfig
    module HashMerger
      refine ::Hash do
        def deep_merge(second)
          merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
          self.merge(second.to_h, &merger)
        end
      end
    end
  end
end
