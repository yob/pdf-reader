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
  class XRef
    ################################################################################
    # create a new Xref table based on the contents of the supplied PDF::Reader::Buffer object
    def initialize (buffer)
      @buffer = buffer
      @xref = {}
    end
    ################################################################################
    # Read the xref table from the underlying buffer. If offset is specified the table
    # will be loaded from there, otherwise the default offset will be located and used.
    #
    # Will fail silently if there is no xref table at the requested offset.
    def load (offset = nil)
      offset ||= @buffer.find_first_xref_offset
      @buffer.seek(offset)
      token = @buffer.token
      
      if token == "xref" || token == "ref"
        load_xref_table
      else
        raise PDF::Reader::MalformedPDFError, "xref table not found at offset #{offset} (#{token} != xref)"
      end
    end
    ################################################################################
    # Return a string containing the contents of an entire PDF object. The object is requested
    # by specifying a PDF::Reader::Reference object that contains the objects ID and revision
    # number
    #
    # If the object is a stream, that is returned as well
    def object (ref, save_pos = true)
      return ref, nil unless ref.kind_of?(Reference)
      pos = @buffer.pos if save_pos
      obj, stream = Parser.new(@buffer.seek(offset_for(ref)), self).object(ref.id, ref.gen)
      @buffer.seek(pos) if save_pos
      if stream
        return [obj, stream]
      else
        return [obj, nil]
      end
    end
    ################################################################################
    # Assumes the underlying buffer is positioned at the start of an Xref table and
    # processes it into memory.
    def load_xref_table
      tok_one = tok_two = nil

      begin
        # loop over all subsections of the xref table
        # In a well formed PDF, the 'trailer' token will indicate
        # the end of the table. However we need to be careful in case 
        # we're processing a malformed pdf that is missing the trailer.
        loop do
          tok_one, tok_two = @buffer.token, @buffer.token
          if tok_one != "trailer" && !tok_one.match(/\d+/)
            raise MalformedPDFError, "PDF malformed, missing trailer after cross reference"
          end
          break if tok_one == "trailer" or tok_one.nil?
          objid, count = tok_one.to_i, tok_two.to_i

          count.times do
            offset = @buffer.token.to_i
            generation = @buffer.token.to_i
            state = @buffer.token

            store(objid, generation, offset) if state == "n"
            objid += 1
          end
        end
      rescue EOFError => e
        raise MalformedPDFError, "PDF malformed, missing trailer after cross reference"
      end

      raise MalformedPDFError, "PDF malformed, trailer should be a dictionary" unless tok_two == "<<"

      trailer = Parser.new(@buffer, self).dictionary
      load(trailer['Prev'].to_i) if trailer.has_key?('Prev')

      trailer
    end
    # returns the type of object a ref points to
    def obj_type(ref)
      obj, stream = object(ref)
      obj.class.to_s.to_sym
    end
    # returns true if the supplied references points to an object with a stream
    def stream?(ref)
      obj, stream = @xref.object(ref)
      stream ? true : false
    end
    ################################################################################
    # returns the byte offset for the specified PDF object.
    #
    # ref - a PDF::Reader::Reference object containing an object ID and revision number
    def offset_for (ref)
      @xref[ref.id][ref.gen]
    end
    ################################################################################
    # Stores an offset value for a particular PDF object ID and revision number
    def store (id, gen, offset)
      (@xref[id] ||= {})[gen] ||= offset
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
