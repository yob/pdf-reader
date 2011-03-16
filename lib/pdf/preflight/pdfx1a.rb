# coding: utf-8

module PDF
  module Preflight
    class PDFX1A
      def check(input)
        if File.file?(input)
          check_filename(input)
        elsif input.is_a?(IO)
          check_io(input)
        else
          raise ArgumentError, "input must be a string with a filename or an IO object"
        end
      end

      private

      def check_filename(filename)
        File.open(filename, "rb") do |file|
          return check_io(file)
        end
      end

      # TODO: this is nasty, we parse the full file once for each receiver.
      #       PDF::Reader needs to be updated to support multiple receivers
      #
      def check_io(io)
        receivers.select { |rec|
          PDF::Reader.new.parse(io, rec)
          rec.fail?
        }.map { |rec|
          rec.message
        }
      end

      def receivers
        [
          PDF::Preflight::Receivers::MaxVersion.new(1.3)
        ]
      end
    end
  end
end
