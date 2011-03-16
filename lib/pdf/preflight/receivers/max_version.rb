# coding: utf-8

module PDF
  module Preflight
    module Receivers
      class MaxVersion
        attr_reader :message

        def initialize(max_version)
          @max_version = max_version.to_f
          @message = "No version information available"
        end

        def pdf_version(arg = nil)
          if arg <= @max_version
            @message = nil
          else
            @message = "PDF version should be #{@max_version} or lower (value: #{arg})"
          end
        end
      end
    end
  end
end
