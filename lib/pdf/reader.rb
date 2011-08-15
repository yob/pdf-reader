################################################################################
#
# Copyright (C) 2006 Peter J Jones (pjones@pmade.com)
# Copyright (C) 2011 James Healy
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
  # The Reader class serves as an entry point for parsing a PDF file.
  #
  # PDF is a page based file format. There is some data associated with the
  # document (metadata, bookmarks, etc) but all visible content is stored
  # under a Page object.
  #
  # In most use cases for extracting and examining the contents of a PDF it
  # makes sense to traverse the information using page based iteration.
  #
  # In addition to the documentation here, check out the
  # PDF::Reader::Page class.
  #
  # == File Metadata
  #
  #   reader = PDF::Reader.new("somefile.pdf")
  #
  #   puts reader.pdf_version
  #   puts reader.info
  #   puts reader.metadata
  #   puts reader.page_count
  #
  # == Iterating over page content
  #
  #   reader = PDF::Reader.new("somefile.pdf")
  #
  #   reader.pages.each do |page|
  #     puts page.fonts
  #     puts page.images
  #     puts page.text
  #   end
  #
  # == Extracting all text
  #
  #   reader = PDF::Reader.new("somefile.pdf")
  #
  #   reader.pages.map(&:text)
  #
  # == Extracting content from a single page
  #
  #   reader = PDF::Reader.new("somefile.pdf")
  #
  #   page = reader.page(1)
  #   puts page.fonts
  #   puts page.images
  #   puts page.text
  #
  # == Low level callbacks (ala current version of PDF::Reader)
  #
  #   reader = PDF::Reader.new("somefile.pdf")
  #
  #   page = reader.page(1)
  #   page.walk(receiver)
  #
  class Reader

    # lowlevel hash-like access to all objects in the underlying PDF
    attr_reader :objects

    # creates a new document reader for the provided PDF.
    #
    # input can be an IO-ish object (StringIO, File, etc) containing a PDF
    # or a filename
    #
    #   reader = PDF::Reader.new("somefile.pdf")
    #
    #   File.open("somefile.pdf","rb") do |file|
    #     reader = PDF::Reader.new(file)
    #   end
    #
    def initialize(input = nil)
      if input # support the deprecated Reader API
        @objects = PDF::Reader::ObjectHash.new(input)
      end
    end

    def info
      @objects.deref(@objects.trailer[:Info])
    end

    def metadata
      stream = @objects.deref(root[:Metadata])
      stream ? stream.unfiltered_data : nil
    end

    def page_count
      pages = @objects.deref(root[:Pages])
      @page_count ||= pages[:Count]
    end

    def pdf_version
      @objects.pdf_version
    end

    # syntactic sugar for opening a PDF file. Accepts the same arguments
    # as new().
    #
    #   PDF::Reader.open("somefile.pdf") do |reader|
    #     puts reader.pdf_version
    #   end
    #
    def self.open(input, &block)
      yield PDF::Reader.new(input)
    end

    # DEPRECATED: this method was deprecated in version 0.11.0 and will
    #             eventually be removed
    #
    #
    # Parse the file with the given name, sending events to the given receiver.
    #
    def self.file(name, receivers, opts = {})
      File.open(name,"rb") do |f|
        new.parse(f, receivers, opts)
      end
    end

    # DEPRECATED: this method was deprecated in version 0.11.0 and will
    #             eventually be removed
    #
    # Parse the given string, sending events to the given receiver.
    #
    def self.string(str, receivers, opts = {})
      StringIO.open(str) do |s|
        new.parse(s, receivers, opts)
      end
    end

    # DEPRECATED: this method was deprecated in version 0.11.0 and will
    #             eventually be removed
    #
    # Parse the file with the given name, returning an unmarshalled ruby version of
    # represents the requested pdf object
    #
    def self.object_file(name, id, gen = 0)
      File.open(name,"rb") { |f|
        new.object(f, id.to_i, gen.to_i)
      }
    end

    # DEPRECATED: this method was deprecated in version 0.11.0 and will
    #             eventually be removed
    #
    # Parse the given string, returning an unmarshalled ruby version of represents
    # the requested pdf object
    #
    def self.object_string(str, id, gen = 0)
      StringIO.open(str) { |s|
        new.object(s, id.to_i, gen.to_i)
      }
    end

    # returns an array of PDF::Reader::Page objects, one for each
    # page in the source PDF.
    #
    #   reader = PDF::Reader.new("somefile.pdf")
    #
    #   reader.pages.each do |page|
    #     puts page.fonts
    #     puts page.images
    #     puts page.text
    #   end
    #
    # See the docs for PDF::Reader::Page to read more about the
    # methods available on each page
    #
    def pages
      (1..self.page_count).map { |num|
        PDF::Reader::Page.new(@objects, num)
      }
    end

    # returns a single PDF::Reader::Page for the specified page.
    # Use this instead of pages method when you need to access just a single
    # page
    #
    #   reader = PDF::Reader.new("somefile.pdf")
    #   page   = reader.page(10)
    #
    #   puts page.text
    #
    # See the docs for PDF::Reader::Page to read more about the
    # methods available on each page
    #
    def page(num)
      num = num.to_i
      raise ArgumentError, "valid pages are 1 .. #{self.page_count}" if num < 1 || num > self.page_count
      PDF::Reader::Page.new(@objects, num)
    end


    # DEPRECATED: this method was deprecated in version 0.11.0 and will
    #             eventually be removed
    #
    # Given an IO object that contains PDF data, parse it.
    #
    def parse(io, receivers, opts = {})
      ohash    = ObjectHash.new(io)

      if ohash.trailer[:Encrypt]
        raise ::PDF::Reader::UnsupportedFeatureError, 'PDF::Reader cannot read encrypted PDF files'
      end

      options = {:pages => true, :raw_text => false, :metadata => true}
      options.merge!(opts)

      strategies.each do |s|
        s.new(ohash, receivers, options).process
      end

      self
    end

    # DEPRECATED: this method was deprecated in version 0.11.0 and will
    #             eventually be removed
    #
    # Given an IO object that contains PDF data, return the contents of a single object
    #
    def object (io, id, gen)
      @objects = ObjectHash.new(io)

      @objects.deref(Reference.new(id, gen))
    end

    private

    def strategies
      @strategies ||= [
        ::PDF::Reader::MetadataStrategy,
        ::PDF::Reader::PagesStrategy
      ]
    end

    def root
      @root ||= @objects.deref(@objects.trailer[:Root])
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
require 'pdf/reader/form_xobject'
require 'pdf/reader/glyph_hash'
require 'pdf/reader/lzw'
require 'pdf/reader/metadata_strategy'
require 'pdf/reader/object_cache'
require 'pdf/reader/object_hash'
require 'pdf/reader/object_stream'
require 'pdf/reader/pages_strategy'
require 'pdf/reader/parser'
require 'pdf/reader/print_receiver'
require 'pdf/reader/reference'
require 'pdf/reader/register_receiver'
require 'pdf/reader/stream'
require 'pdf/reader/text_receiver'
require 'pdf/reader/page_text_receiver'
require 'pdf/reader/token'
require 'pdf/reader/xref'
require 'pdf/reader/page'
require 'pdf/hash'
