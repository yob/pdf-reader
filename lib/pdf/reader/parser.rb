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
    # xref   - an integer that specifies the byte offset of the xref table in the buffer
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
      when "/"                        : return Name.new(@buffer.token)
      when "<<"                       : return dictionary()
      when "["                        : return array()
      when "("                        : return string()
      when "<"                        : return hex_string()
      when "true"                     : return true
      when "false"                    : return false
      when "null"                     : return nil
      when "obj", "endobj"            : return Token.new(token)
      when "stream", "endstream"      : return Token.new(token)
      when ">>", "]", ">"             : return Token.new(token)
      else                          
        if operators.has_key?(token)  : return Token.new(token)
        else                            return token.to_f
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
        raise MalformedPDFError, "PDF malformed, dictionary key is not a name" unless key.kind_of?(Name)

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
      str = @buffer.token
      Error.str_assert(@buffer.token, ">")

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
        i = @buffer.raw.index(/[\\\(\)]/)

        if i.nil?
          str << @buffer.raw + "\n"
          @buffer.raw.replace("")
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
          when ""   : to_remove = 1
          when "n"  : str << "\n"
          when "r"  : str << "\r"
          when "t"  : str << "\t"
          when "b"  : str << "\b"
          when "f"  : str << "\f"
          when "("  : str << "("
          when ")"  : str << ")"
          when "\\" : str << "\\"
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
      when "endobj"   : return obj
      when "stream"   : return stream(obj)
      else              raise MalformedPDFError, "PDF malformed, unexpected token #{post_obj}"
      end
    end
    ################################################################################
    # Decodes the contents of a PDF Stream and returns it as a Ruby String.
    def stream (dict)
      raise MalformedPDFError, "PDF malformed, missing stream length" unless dict.has_key?('Length')
      dict['Length'] = @xref.object(dict['Length']) if dict['Length'].kind_of?(Reference)
      data = @buffer.read(dict['Length'])
      Error.str_assert(parse_token, "endstream")
      Error.str_assert(parse_token, "endobj")

      if dict.has_key?('Filter')
        options = []

        if dict.has_key?('DecodeParms')
          options = dict['DecodeParms'].to_a
        end

        dict['Filter'].to_a.each_with_index do |filter, index|
          data = Filter.new(filter, options[index]).filter(data)
        end
      end

      data
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
