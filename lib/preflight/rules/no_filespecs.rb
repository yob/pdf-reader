# coding: utf-8

module Preflight
  module Rules

    # PDF/X files are not allowed to use Filespecs to refer
    # to external files.
    #
    class NoFilespecs

      def check_hash(ohash)
        if count_filespec_dicts(ohash) > 0
          ["File uses at least 1 Filespec to refer to an external file"]
        else
          []
        end
      end

      private

      def count_filespec_dicts(ohash)
        ohash.select { |key, obj|
          obj.is_a?(::Hash) && (obj[:Type] == :Filespec || obj[:Type] == :F)
        }.size
      end
    end
  end
end
