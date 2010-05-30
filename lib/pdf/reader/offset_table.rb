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
  # An internal PDF::Reader class that represents the Xref table in a PDF file
  # An Xref table is a map of object identifiers and byte offsets. Any time a particular
  # object needs to be found, the Xref table is used to find where it is stored in the
  # file.
  class OffsetTable
    include Enumerable
    attr_reader :trailer

    ################################################################################
    # create a new Xref table based on the contents of the supplied PDF::Reader::Buffer object
    def initialize (io)
      @io = io
      @xref = {}
      @trailer = load_offsets
    end
    def size
      @xref.size
    end
    ################################################################################
    # returns the byte offset for the specified PDF object.
    #
    # ref - a PDF::Reader::Reference object containing an object ID and revision number
    def [](ref)
      @xref[ref.id][ref.gen]
    rescue
      raise InvalidObjectError, "Object #{ref.id}, Generation #{ref.gen} is invalid"
    end
    ################################################################################
    # iterate over each object in the xref table
    def each(&block)
      ids = @xref.keys.sort
      ids.each do |id|
        gen = @xref[id].keys.sort[-1]
        yield PDF::Reader::Reference.new(id, gen)
      end
    end
    ################################################################################
    private
    ################################################################################
    # Read the xref table from the underlying buffer. If offset is specified the table
    # will be loaded from there, otherwise the default offset will be located and used.
    #
    # Will fail silently if there is no xref table at the requested offset.
    def load_offsets (offset = nil)
      offset ||= new_buffer.find_first_xref_offset

      buf = new_buffer(offset)
      tok_one = buf.token

      return load_xref_table(buf) if tok_one == "xref" || tok_one == "ref"

      tok_two   = buf.token
      tok_three = buf.token

      if tok_one.to_i >= 0 && tok_two.to_i >= 0 && tok_three == "obj"
        buf = new_buffer(offset)
        stream = PDF::Reader::Parser.new(buf).object(tok_one.to_i, tok_two.to_i)
        return load_xref_stream(stream)
      end

      raise PDF::Reader::MalformedPDFError, "xref table not found at offset #{offset} (#{tok_one} != xref)"
    end
    ################################################################################
    def load_xref_stream(stream)
      unless stream.hash[:Type] == :XRef
        raise PDF::Reader::MalformedPDFError, "xref stream not found when expected"
      end
      trailer = {}
      trailer[:Root] = stream.hash[:Root] if stream.hash[:Root]
      trailer[:Info] = stream.hash[:Info] if stream.hash[:Info]
      trailer[:Prev] = stream.hash[:Prev] if stream.hash[:Prev]

      widths = stream.hash[:W]
      entry_length = widths.inject(0) { |s, w| s + w }
      raw_data = stream.unfiltered_data
      if stream.hash[:Index]
        index = stream.hash[:Index][0]
      else
        index = 0
      end
      stream.hash[:Size].times do |i|
        entry = raw_data[i*entry_length, entry_length]
        f1    = unpack_bytes(entry[0,widths[0]])
        f2    = unpack_bytes(entry[widths[0],widths[1]])
        f3    = unpack_bytes(entry[widths[0]+widths[1],widths[2]])
        if f1 == 1
          store(index + i, f3, f2)
        elsif f1 == 2
          store(index + i, 0, [f2, f3])
        end
      end

      load_offsets(trailer[:Prev].to_i) if trailer.has_key?(:Prev)

      trailer
    end
    ################################################################################
    def unpack_bytes(bytes)
      if bytes.size == 1
        bytes.unpack("C")[0]
      elsif bytes.size == 2
        bytes.unpack("n")[0]
      elsif bytes.size == 3
        ("\x00" + bytes).unpack("N")[0]
      elsif bytes.size == 4
        bytes.unpack("N")[0]
      else
        raise UnsupportedFeatureError, "Unable to unpack xref stream entries with more than 4 bytes"
      end
    end
    ################################################################################
    # Assumes the underlying buffer is positioned at the start of an Xref table and
    # processes it into memory.
    def load_xref_table(buf)
      params = []

      while !params.include?("trailer") && !params.include?(nil)
        if params.size == 2
          objid, count = params[0].to_i, params[1].to_i
          count.times do
            offset = buf.token.to_i
            generation = buf.token.to_i
            state = buf.token

            store(objid, generation, offset) if state == "n"
            objid += 1
            params.clear
          end
        end
        params << buf.token
      end

      trailer = Parser.new(buf, self).parse_token

      raise MalformedPDFError, "PDF malformed, trailer should be a dictionary" unless trailer.kind_of?(Hash)

      load_offsets(trailer[:Prev].to_i) if trailer.has_key?(:Prev)

      trailer
    end

    def new_buffer(offset = 0)
      PDF::Reader::Buffer.new(@io, :seek => offset)
    end

    ################################################################################
    # Stores an offset value for a particular PDF object ID and revision number
    def store (id, gen, offset)
      (@xref[id] ||= {})[gen] ||= offset
    end
  end
  ################################################################################
end
################################################################################
