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
    def initialize (buffer, xref)
      @buffer = buffer
      @xref   = xref
    end
    ################################################################################
    # Reads the next token from the underlying buffer and convets it to an appropriate
    # object
    #
    # operators - a hash of supported operators to read from the underlying buffer.
    def parse_token (operators={})
      ref = Reference.from_buffer(@buffer) and return ref
      token = @buffer.token

      case token
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
      when ">>", "]", ">"             then return Token.new(token)
      else
        if operators.has_key?(token)  then return Token.new(token)
        elsif token =~ /\d*\.\d/      then return token.to_f
        else                          return token.to_i
        end
      end
    end
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
      str = ""
      count = 1

      while count != 0
        @buffer.ready_token(false, false)

        # find the first occurance of ( ) [ \ or ]
        #
        # I originally just used the regexp form of index(), but it seems to be
        # buggy on some OSX systems (returns nil when there is a match). This
        # version is more reliable and was suggested by Andrès Koetsier.
        #
        i = nil
        @buffer.raw.unpack("C*").each_with_index do |charint, idx|
          if [40, 41, 91, 92, 93].include?(charint)
            i = idx
            break
          end
        end

        if i.nil?
          str << @buffer.raw + "\n"
          @buffer.raw.replace("")
          # if a content stream opens a string, but never closes it, we'll
          # hit the end of the stream and still be appending stuff to the
          # string. bad! This check prevents a hard loop.
          raise MalformedPDFError, 'unterminated string in content stream' if @buffer.eof?
          next
        end

        str << @buffer.head(i, false)
        to_remove = 1

        case @buffer.raw[0, 1]
        when "("
          str << "("
          count += 1
        when ")"
          count -= 1
          str << ")" unless count == 0
        when "\\"
          to_remove = 2
          case @buffer.raw[1, 1]
          when ""   then to_remove = 1
          when "n"  then str << "\n"
          when "r"  then str << "\r"
          when "t"  then str << "\t"
          when "b"  then str << "\b"
          when "f"  then str << "\f"
          when "("  then str << "("
          when ")"  then str << ")"
          when "\\" then str << "\\"
          else
            if m = @buffer.raw.match(/^\\(\d{1,3})/)
              to_remove = m[0].size
              str << m[1].oct.chr
            end
          end
        end

        @buffer.head(to_remove, false)
      end
      str
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
    ################################################################################
    # Decodes the contents of a PDF Stream and returns it as a Ruby String.
    def stream (dict)
      raise MalformedPDFError, "PDF malformed, missing stream length" unless dict.has_key?(:Length)
      data = @buffer.read(@xref.object(dict[:Length]))

      Error.str_assert(parse_token, "endstream")
      Error.str_assert(parse_token, "endobj")

      if dict.has_key?(:Filter)
        options = []

        if dict.has_key?(:DecodeParms)
          options = Array(dict[:DecodeParms])
        end

        Array(dict[:Filter]).each_with_index do |filter, index|
          data = Filter.new(filter, options[index]).filter(data)
        end
      end

      PDF::Reader::Stream.new(dict, data)
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
