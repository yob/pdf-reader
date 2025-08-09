# coding: utf-8
# typed: strict
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
  # An internal PDF::Reader class that represents a stream object from a PDF. Stream
  # objects have 2 components, a dictionary that describes the content (size,
  # compression, etc) and a stream of bytes.
  #
  class Stream
    #: Hash[Symbol, untyped]
    attr_accessor :hash

    #: String
    attr_accessor :data

    ################################################################################
    # Creates a new stream with the specified dictionary and data. The dictionary
    # should be a standard ruby hash, the data should be a standard ruby string.
    #: (Hash[Symbol, untyped], String) -> void
    def initialize(hash, data)
      @hash = TypeCheck.cast_to_pdf_dict!(hash) #: Hash[Symbol, untyped]
      @data = data
      @udata = nil #: String | nil
    end
    ################################################################################
    # apply this streams filters to its data and return the result.
    #: () -> String
    def unfiltered_data
      return @udata if @udata
      @udata = data.dup

      if hash.has_key?(:Filter)
        options = []

        if hash.has_key?(:DecodeParms)
          if hash[:DecodeParms].is_a?(Hash)
            options = [hash[:DecodeParms]]
          else
            options = hash[:DecodeParms]
          end
        end

        Array(hash[:Filter]).each_with_index do |filter, index|
          @udata = Filter.with(filter, options[index] || {}).filter(@udata)
        end
      end
      @udata
    end
  end
  ################################################################################
end
################################################################################
