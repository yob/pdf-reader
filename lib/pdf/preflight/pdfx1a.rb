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
        check_receivers(io) + check_hash(io)
      end

      def check_receivers(io)
        receivers.map { |rec|
          begin
            PDF::Reader.new.parse(io, rec)
            rec.message
          rescue PDF::Reader::UnsupportedFeatureError
            nil
          end
        }.compact
      end

      def check_hash(io)
        ohash = PDF::Reader::ObjectHash.new(io)

        hash_checks.map { |chk|
          chk.message(ohash)
        }.compact
      end

      def hash_checks
        [
          PDF::Preflight::Checks::NoEncryption.new,
          PDF::Preflight::Checks::CompressionAlgorithms.new(:CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode)
        ]
      end

      def receivers
        [
          PDF::Preflight::Receivers::MaxVersion.new(1.4)
        ]
      end
    end
  end
end
