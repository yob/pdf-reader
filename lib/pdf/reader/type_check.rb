# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader

    # Cast untrusted input (usually parsed out of a PDF file) to a known type
    #
    class TypeCheck

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
    end
  end
end

