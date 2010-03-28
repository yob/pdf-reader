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
    ################################################################################
    # Create a new parser around a PDF::Reader::Buffer object
    #
    # buffer - a PDF::Reader::Buffer object that contains PDF data
    # xref   - a PDF::Reader::XRef object that represents the document's object offsets
    def initialize (buffer, xref=nil)
      @buffer = buffer
      @xref   = xref
    end
    ################################################################################
    # Reads the next token from the underlying buffer and convets it to an appropriate
    # object
    #
    # operators - a hash of supported operators to read from the underlying buffer.
    def parse_token (operators={})
      token = @buffer.token

      case token
      when PDF::Reader::Reference     then return token
      when nil                        then return nil
      when "/"                        then return @buffer.token.to_sym
      when "<<"                       then return dictionary()
      when "["                        then return array()
      when "("                        then return string()
      when "<"                        then return hex_string()
      when "true"                     then return true
      when "false"                    then return false
      when "null"                     then return nil
      when "obj", "endobj"            then return Token.new(token)
      when "stream", "endstream"      then return Token.new(token)
      when ">>", "]", ">", ")"        then return Token.new(token)
      else
        if operators.has_key?(token)  then return Token.new(token)
        elsif token =~ /\d*\.\d/      then return token.to_f
        else                          return token.to_i
        end
      end
    end
    ################################################################################
    # Reads an entire PDF object from the buffer and returns it as a Ruby String.
    # If the object is a content stream, returns both the stream and the dictionary
    # that describes it
    #
    # id  - the object ID to return
    # gen - the object revision number to return
    def object (id, gen)
      Error.assert_equal(parse_token, id)
      Error.assert_equal(parse_token, gen)
      Error.str_assert(parse_token, "obj")

      obj = parse_token
      post_obj = parse_token
      case post_obj
      when "endobj"   then return obj
      when "stream"   then return stream(obj)
      else            raise MalformedPDFError, "PDF malformed, unexpected token #{post_obj}"
      end
    end

    private

    ################################################################################
    # reads a PDF dict from the buffer and converts it to a Ruby Hash.
    def dictionary
      dict = {}

      loop do
        key = parse_token
        break if key.kind_of?(Token) and key == ">>"
        raise MalformedPDFError, "Dictionary key (#{key.inspect}) is not a name" unless key.kind_of?(Symbol)

        value = parse_token
        value.kind_of?(Token) and Error.str_assert_not(value, ">>")
        dict[key] = value
      end

      dict
    end
    ################################################################################
    # reads a PDF array from the buffer and converts it to a Ruby Array.
    def array
      a = []

      loop do
        item = parse_token
        break if item.kind_of?(Token) and item == "]"
        a << item
      end

      a
    end
    ################################################################################
    # Reads a PDF hex string from the buffer and converts it to a Ruby String
    def hex_string
      str = ""

      loop do
        token = @buffer.token
        break if token == ">"
        str << token
      end

      # add a missing digit if required, as required by the spec
      str << "0" unless str.size % 2 == 0
      str.scan(/../).map {|i| i.hex.chr}.join
    end
    ################################################################################
    # Reads a PDF String from the buffer and converts it to a Ruby String
    def string
      str = @buffer.token
      return "" if str == ")"
      Error.assert_equal(parse_token, ")")

      str.gsub!("\\n","\n")
      str.gsub!("\\r","\r")
      str.gsub!("\\t","\t")
      str.gsub!("\\b","\b")
      str.gsub!("\\f","\f")
      str.gsub!("\\(","(")
      str.gsub!("\\)",")")
      str.gsub!("\\\\","\\")
      str.gsub!(/\\\n/m,"")
      str.gsub!(/(\n\r|\r\n|\r)/m,"\n")

      str.scan(/\\\d{1,3}/).each do |octal|
        str.gsub!(octal, octal[1,3].oct.chr)
      end

      str.gsub!(/\\([^\\])/,'\1')

      str
    end
    ################################################################################
    # Decodes the contents of a PDF Stream and returns it as a Ruby String.
    def stream (dict)
      raise MalformedPDFError, "PDF malformed, missing stream length" unless dict.has_key?(:Length)
      data = @buffer.read(@xref.object(dict[:Length]), :skip_eol => true)

      Error.str_assert(parse_token, "endstream")
      Error.str_assert(parse_token, "endobj")

      PDF::Reader::Stream.new(dict, data)
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
