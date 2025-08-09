# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader

  # provides a wrapper around a PDF stream object that contains other objects in it.
  # This is done for added compression and is described as an "Object Stream" in the spec.
  #
  class ObjectStream # :nodoc:
    #: (PDF::Reader::Stream) -> void
    def initialize(stream)
      @dict = stream.hash #: Hash[Symbol, untyped]
      @data = stream.unfiltered_data #: String
      @offsets = nil #: Hash[Integer, Integer] | nil
      @buffer = nil #: PDF::Reader::Buffer | nil
    end

    #: (Integer) -> (
    #|   PDF::Reader::Reference |
    #|   PDF::Reader::Token |
    #|   Numeric |
    #|   String |
    #|   Symbol |
    #|   Array[untyped] |
    #|   Hash[untyped, untyped] |
    #|   nil
    #| )
    def [](objid)
      if offsets[objid].nil?
        nil
      else
        buf = PDF::Reader::Buffer.new(StringIO.new(@data), :seek => offsets[objid])
        parser = PDF::Reader::Parser.new(buf)
        parser.parse_token
      end
    end

    #: () -> Integer
    def size
      TypeCheck.cast_to_int!(@dict[:N])
    end

    private

    #: () -> Hash[Integer, Integer]
    def offsets
      @offsets ||= {}
      return @offsets if @offsets.keys.size > 0

      size.times do
        @offsets[buffer.token.to_i] = first + buffer.token.to_i
      end
      @offsets
    end

    #: () -> Integer
    def first
      TypeCheck.cast_to_int!(@dict[:First])
    end

    #: () -> PDF::Reader::Buffer
    def buffer
      @buffer ||= PDF::Reader::Buffer.new(StringIO.new(@data))
    end

  end

end

