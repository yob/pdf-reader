# coding: utf-8

module Preflight
  module Rules
    # ensure the PDF version of the file under review is not more recent
    # than desired
    class MaxVersion

      def initialize(max_version)
        @max_version = max_version.to_f
      end

      def messages(ohash)
        if ohash.pdf_version > @max_version
          ["PDF version should be #{@max_version} or lower (value: #{ohash.pdf_version})"]
        else
          []
        end
      end
    end
  end
end
