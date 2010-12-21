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
    # ohash  - a PDF::Reader::ObjectHash object that can return objects from the PDF file
    def initialize (buffer, ohash=nil)
      @buffer = buffer
      @ohash  = ohash
    end
    ################################################################################
    # Reads the next token from the underlying buffer and convets it to an appropriate
    # object
    #
    # operators - a hash of supported operators to read from the underlying buffer.
    def parse_token (operators={})
      token = @buffer.token

      case token
      when PDF::Reader::Reference, nil then return token
      when "/"                         then return pdf_name()
      when "<<"                        then return dictionary()
      when "["                         then return array()
      when "("                         then return string()
      when "<"                         then return hex_string()
      when "true"                      then return true
      when "false"                     then return false
      when "null"                      then return nil
      when "obj", "endobj", "stream", "endstream" then return Token.new(token)
      when "stream", "endstream"       then return Token.new(token)
      when ">>", "]", ">", ")"         then return Token.new(token)
      else
        if operators.has_key?(token)   then return Token.new(token)
        elsif token =~ /\d*\.\d/       then return token.to_f
        else                           return token.to_i
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
      if post_obj == "stream"
        stream(obj)
      else
        obj
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
    # reads a PDF name from the buffer and converts it to a Ruby Symbol
    def pdf_name
      tok = @buffer.token
      tok.scan(/#([A-Fa-f0-9]{2})/).each do |find|
        replace = find[0].hex.chr
        tok.gsub!("#"+find[0], replace)
      end
      tok.to_sym
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

      ret = ""
      idx = 0

      while idx < str.size
        chr = str[idx,1]
        jump = 1

        if chr == "\\"
          jump = 2
          case str[idx+1, 1]
          when "" then jump = 1
          when "n"  then chr = "\n"
          when "r"  then chr = "\r"
          when "t"  then chr = "\t"
          when "b"  then chr = "\b"
          when "f"  then chr = "\f"
          when "("  then chr = "("
          when ")"  then chr = ")"
          when "\\" then chr = "\\"
          when "\n" then
            chr = ""
            jump = 2
          else
            if str[idx+1,3].match(/\d{3}/)
              jump = 4
              chr = str[idx+1,3].oct.chr
            elsif str[idx+1,2].match(/\d{2}/)
              jump = 3
              chr = ("0"+str[idx+1,2]).oct.chr
            elsif str[idx+1,1].match(/\d/)
              jump = 2
              chr = ("00"+str[idx+1,1]).oct.chr
            else
              jump = 1
              chr = ""
            end

          end
        elsif chr == "\r" && str[idx+1,1] == "\n"
          chr = "\n"
          jump = 2
        elsif chr == "\n" && str[idx+1,1] == "\r"
          chr = "\n"
          jump = 2
        elsif chr == "\r"
          chr = "\n"
        end
        ret << chr
        idx += jump
      end
      ret
    end
    ################################################################################
    # Decodes the contents of a PDF Stream and returns it as a Ruby String.
    def stream (dict)
      raise MalformedPDFError, "PDF malformed, missing stream length" unless dict.has_key?(:Length)
      if @ohash
        length = @ohash.object(dict[:Length])
      else
        length = dict[:Length] || 0
      end
      data = @buffer.read(length, :skip_eol => true)

      Error.str_assert(parse_token, "endstream")
      Error.str_assert(parse_token, "endobj")

      PDF::Reader::Stream.new(dict, data)
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
