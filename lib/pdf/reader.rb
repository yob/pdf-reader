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

require 'stringio'
require 'zlib'

require 'ascii85'

module PDF
  ################################################################################
  # The Reader class serves as an entry point for parsing a PDF file. There are three
  # ways to kick off processing - which one you pick will be based on personal preference
  # and the situation.
  #
  # For all examples, assume the receiver variable contains an object that will respond
  # to various callbacks. Refer to the README and PDF::Reader::Content for more information
  # on receivers.
  #
  # = Parsing a file
  #
  #   PDF::Reader.file("somefile.pdf", receiver)
  #
  # = Parsing a String
  #
  # This is useful for processing a PDF that is already in memory
  #
  #   PDF::Reader.string(pdf_string, receiver)
  #
  # = Parsing an IO object
  #
  # This can be a useful alternative to the first 2 options in some situations
  #
  #   pdf = PDF::Reader.new
  #   pdf.parse(File.new("somefile.pdf"), receiver)
  #
  # = Parsing parts of a file
  #
  # Both PDF::Reader#file and PDF::Reader#string accept a third argument that
  # specifies which parts of the file to process. By default, all options are
  # enabled, so this can be useful to cut down processing time if you're only
  # interested in say, metadata.
  #
  # As an example, the following call will disable parsing the contents of
  # pages in the file, but explicitly enables processing metadata.
  #
  #   PDF::Reader.new("somefile.pdf", receiver, {:metadata => true, :pages => false})
  #
  # Available options are currently:
  #
  #   :metadata
  #   :pages
  #   :raw_text
  #
  class Reader

    # Parse the file with the given name, sending events to the given receiver.
    #
    def self.file(name, receiver, opts = {})
      File.open(name,"rb") do |f|
        new.parse(f, receiver, opts)
      end
    end

    # Parse the given string, sending events to the given receiver.
    #
    def self.string(str, receiver, opts = {})
      StringIO.open(str) do |s|
        new.parse(s, receiver, opts)
      end
    end

    # Parse the file with the given name, returning an unmarshalled ruby version of
    # represents the requested pdf object
    #
    def self.object_file(name, id, gen = 0)
      File.open(name,"rb") { |f|
        new.object(f, id.to_i, gen.to_i)
      }
    end

    # Parse the given string, returning an unmarshalled ruby version of represents
    # the requested pdf object
    #
    def self.object_string(str, id, gen = 0)
      StringIO.open(str) { |s|
        new.object(s, id.to_i, gen.to_i)
      }
    end

    # Given an IO object that contains PDF data, parse it.
    #
    def parse(io, receiver, opts = {})
      ohash    = ObjectHash.new(io)

      if ohash.trailer[:Encrypt]
        raise ::PDF::Reader::UnsupportedFeatureError, 'PDF::Reader cannot read encrypted PDF files'
      end

      options = {:pages => true, :raw_text => false, :metadata => true}
      options.merge!(opts)

      strategies.each do |s|
        s.new(ohash, receiver, options).process
      end

      self
    end

    # Given an IO object that contains PDF data, return the contents of a single object
    #
    def object (io, id, gen)
      @ohash = ObjectHash.new(io)

      @ohash.object(Reference.new(id, gen))
    end

    private

    def strategies
      @strategies ||= [
        ::PDF::Reader::MetadataStrategy,
        ::PDF::Reader::PagesStrategy
      ]
    end
  end
end
################################################################################

require 'pdf/reader/abstract_strategy'
require 'pdf/reader/buffer'
require 'pdf/reader/cmap'
require 'pdf/reader/encoding'
require 'pdf/reader/error'
require 'pdf/reader/filter'
require 'pdf/reader/font'
require 'pdf/reader/lzw'
require 'pdf/reader/metadata_strategy'
require 'pdf/reader/object_hash'
require 'pdf/reader/object_stream'
require 'pdf/reader/pages_strategy'
require 'pdf/reader/parser'
require 'pdf/reader/print_receiver'
require 'pdf/reader/reference'
require 'pdf/reader/register_receiver'
require 'pdf/reader/stream'
require 'pdf/reader/text_receiver'
require 'pdf/reader/token'
require 'pdf/reader/xref'
require 'pdf/hash'
