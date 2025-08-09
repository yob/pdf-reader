# coding: utf-8
# typed: true
# frozen_string_literal: true

################################################################################
#
# Copyright (C) 2006 Peter J Jones (pjones@pmade.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

class PDF::Reader
  ################################################################################
  # An internal PDF::Reader class that reads objects from the PDF file and converts
  # them into useable ruby objects (hash's, arrays, true, false, etc)
  class Parser

    TOKEN_STRATEGY = proc { |parser, token| Token.new(token) } #: Proc

    STRATEGIES = {
      "/"  => proc { |parser, token| parser.send(:pdf_name) },
      "<<" => proc { |parser, token| parser.send(:dictionary) },
      "["  => proc { |parser, token| parser.send(:array) },
      "("  => proc { |parser, token| parser.send(:string) },
      "<"  => proc { |parser, token| parser.send(:hex_string) },

      nil     => proc { nil },
      "true"  => proc { true },
      "false" => proc { false },
      "null"  => proc { nil },

      "obj"       => TOKEN_STRATEGY,
      "endobj"    => TOKEN_STRATEGY,
      "stream"    => TOKEN_STRATEGY,
      "endstream" => TOKEN_STRATEGY,
      ">>"        => TOKEN_STRATEGY,
      "]"         => TOKEN_STRATEGY,
      ">"         => TOKEN_STRATEGY,
      ")"         => TOKEN_STRATEGY
    } #: Hash[String?, Proc]

    ################################################################################
    # Create a new parser around a PDF::Reader::Buffer object
    #
    # buffer - a PDF::Reader::Buffer object that contains PDF data
    # objects  - a PDF::Reader::ObjectHash object that can return objects from the PDF file
    #: (PDF::Reader::Buffer, ?PDF::Reader::ObjectHash?) -> void
    def initialize(buffer, objects=nil)
      @buffer = buffer
      @objects  = objects
    end
    ################################################################################
    # Reads the next token from the underlying buffer and convets it to an appropriate
    # object
    #
    # operators - a hash of supported operators to read from the underlying buffer.
    #: (?Hash[String | PDF::Reader::Token, Symbol]) -> (
    #|   PDF::Reader::Reference |
    #|   PDF::Reader::Token |
    #|   Numeric |
    #|   String |
    #|   Symbol |
    #|   Array[untyped] |
    #|   Hash[untyped, untyped] |
    #|   nil
    #| )
    def parse_token(operators={})
      token = @buffer.token

      if token.nil?
        nil
      elsif token.is_a?(String) && STRATEGIES.has_key?(token)
        proc = STRATEGIES[token]
        proc.call(self, token) if proc
      elsif token.is_a? PDF::Reader::Reference
        token
      elsif operators.has_key? token
        Token.new(token)
      elsif token.frozen?
        token
      elsif token =~ /\d*\.\d/
        token.to_f
      else
        token.to_i
      end
    end
    ################################################################################
    # Reads an entire PDF object from the buffer and returns it as a Ruby String.
    # If the object is a content stream, returns both the stream and the dictionary
    # that describes it
    #
    # id  - the object ID to return
    # gen - the object revision number to return
    #: (Integer, Integer) -> (
    #|   PDF::Reader::Reference |
    #|   PDF::Reader::Token |
    #|   PDF::Reader::Stream |
    #|   Numeric |
    #|   String |
    #|   Symbol |
    #|   Array[untyped] |
    #|   Hash[untyped, untyped] |
    #|   nil
    #| )
    def object(id, gen)
      idCheck = parse_token

      # Sometimes the xref table is corrupt and points to an offset slightly too early in the file.
      # check the next token, maybe we can find the start of the object we're looking for
      if idCheck != id
        Error.assert_equal(parse_token, id)
      end
      Error.assert_equal(parse_token, gen)
      Error.str_assert(parse_token, "obj")

      obj = parse_token
      post_obj = parse_token

      if obj.is_a?(Hash) && post_obj == "stream"
        stream(obj)
      else
        obj
      end
    end

    private

    ################################################################################
    # reads a PDF dict from the buffer and converts it to a Ruby Hash.
    #: () -> Hash[Symbol, untyped]
    def dictionary
      dict = {}

      loop do
        key = parse_token
        break if key.kind_of?(Token) and key == ">>"
        raise MalformedPDFError, "unterminated dict" if @buffer.empty?
        PDF::Reader::Error.validate_type_as_malformed(key, "Dictionary key", Symbol)

        value = parse_token
        value.kind_of?(Token) and Error.str_assert_not(value, ">>")
        dict[key] = value
      end

      dict
    end
    ################################################################################
    # reads a PDF name from the buffer and converts it to a Ruby Symbol
    #: () -> Symbol
    def pdf_name
      tok = @buffer.token

      if tok.is_a?(String)
        tok = tok.dup.gsub(/#([A-Fa-f0-9]{2})/) do |match|
          res = match[1, 2]
          res ? res.hex.chr : ""
        end
        tok.to_sym
      elsif tok.is_a?(PDF::Reader::Reference)
        raise MalformedPDFError, "unexpected reference"
      else
        raise MalformedPDFError, "unexpected nil PDF Name"
      end
    end
    ################################################################################
    # reads a PDF array from the buffer and converts it to a Ruby Array.
    #: () -> Array[untyped]
    def array
      a = []

      loop do
        item = parse_token
        break if item.kind_of?(Token) and item == "]"
        raise MalformedPDFError, "unterminated array" if @buffer.empty?
        a << item
      end

      a
    end
    ################################################################################
    # Reads a PDF hex string from the buffer and converts it to a Ruby String
    #: () -> String
    def hex_string
      str = "".dup

      loop do
        token = @buffer.token
        break if token == ">"
        raise MalformedPDFError, "unterminated hex string" if @buffer.empty?
        str << token
      end

      # add a missing digit if required, as required by the spec
      str << "0" unless str.size % 2 == 0
      [str].pack('H*')
    end
    ################################################################################
    # Reads a PDF String from the buffer and converts it to a Ruby String
    #: () -> String
    def string
      str = @buffer.token
      raise MalformedPDFError, "unexpected reference" if str.is_a?(PDF::Reader::Reference)
      raise MalformedPDFError, "unexpected nil PDF String" if str.nil?
      return "".dup.force_encoding("binary") if str == ")"
      Error.assert_equal(parse_token, ")")

      str.gsub!(/\\(\r\n|[nrtbf()\\\n\r]|([0-7]{1,3}))?|\r\n?/m) do |match|
        if $2.nil? # not octal digits
          MAPPING[match] || "".dup
        else # must be octal digits
          ($2.oct & 0xff).chr # ignore high level overflow
        end
      end
      str.force_encoding("binary")
    end

    MAPPING = {
      "\r"   => "\n",
      "\r\n" => "\n",
      "\\n"  => "\n",
      "\\r"  => "\r",
      "\\t"  => "\t",
      "\\b"  => "\b",
      "\\f"  => "\f",
      "\\("  => "(",
      "\\)"  => ")",
      "\\\\" => "\\",
      "\\\n" => "",
      "\\\r" => "",
      "\\\r\n" => "",
    } #: Hash[String, String]

    ################################################################################
    # Decodes the contents of a PDF Stream and returns it as a Ruby String.
    #: (Hash[Symbol, untyped]) -> PDF::Reader::Stream
    def stream(dict)
      raise MalformedPDFError, "PDF malformed, missing stream length" unless dict.has_key?(:Length)
      if @objects
        length = @objects.deref_integer(dict[:Length])
        if dict[:Filter]
          dict[:Filter] = @objects.deref_name_or_array(dict[:Filter])
        end
      else
        length = dict[:Length] || 0
      end

      PDF::Reader::Error.validate_type_as_malformed(length, "length", Numeric)

      data = @buffer.read(length, :skip_eol => true)

      Error.str_assert(parse_token, "endstream")

      # We used to assert that the stream had the correct closing token, but it doesn't *really*
      # matter if it's missing, and other readers seems to handle its absence just fine
      # Error.str_assert(parse_token, "endobj")

      PDF::Reader::Stream.new(dict, data || "")
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
