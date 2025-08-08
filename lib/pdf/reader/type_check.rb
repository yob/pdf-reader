# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader

    # Cast untrusted input (usually parsed out of a PDF file) to a known type
    #
    class TypeCheck

      #: (untyped) -> Integer
      def self.cast_to_int!(obj)
        if obj.is_a?(Integer)
          obj
        elsif obj.nil?
          0
        elsif obj.respond_to?(:to_i)
          obj.to_i
        else
          raise MalformedPDFError, "Unable to cast to integer"
        end
      end

      #: (untyped) -> Numeric
      def self.cast_to_numeric!(obj)
        if obj.is_a?(Numeric)
          obj
        elsif obj.nil?
          0
        elsif obj.respond_to?(:to_f)
          obj.to_f
        elsif obj.respond_to?(:to_i)
          obj.to_i
        else
          raise MalformedPDFError, "Unable to cast to numeric"
        end
      end

      #: (untyped) -> String
      def self.cast_to_string!(string)
        if string.is_a?(String)
          string
        elsif string.nil?
          ""
        elsif string.respond_to?(:to_s)
          string.to_s
        else
          raise MalformedPDFError, "Unable to cast to string"
        end
      end

      #: (untyped) -> Symbol | nil
      def self.cast_to_symbol(obj)
        if obj.is_a?(Symbol)
          obj
        elsif obj.nil?
          nil
        elsif obj.respond_to?(:to_sym)
          obj.to_sym
        else
          raise MalformedPDFError, "Unable to cast to symbol"
        end
      end

      #: (untyped) -> Symbol
      def self.cast_to_symbol!(obj)
        res = cast_to_symbol(obj)
        if res.nil?
          raise MalformedPDFError, "Unable to cast to symbol"
        else
          res
        end
      end

      #: (untyped) -> Hash[Symbol, untyped]
      def self.cast_to_pdf_dict!(obj)
        if obj.is_a?(Hash)
          obj
        elsif obj.respond_to?(:to_h)
          obj.to_h
        else
          raise MalformedPDFError, "Unable to cast to hash"
        end
      end

      #: (untyped) -> Hash[Symbol, PDF::Reader::Stream]
      def self.cast_to_pdf_dict_with_stream_values!(obj)
        if obj.is_a?(Hash)
          result = Hash.new
          obj.each do |k, v|
            raise MalformedPDFError, "Expected a stream" unless v.is_a?(PDF::Reader::Stream)
            result[cast_to_symbol!(k)] = v
          end
          result
        elsif obj.respond_to?(:to_h)
          cast_to_pdf_dict_with_stream_values!(obj.to_h)
        else
          raise MalformedPDFError, "Unable to cast to hash"
        end
      end
    end
  end
end

