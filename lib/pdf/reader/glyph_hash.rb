# coding: utf-8
# typed: strict
# frozen_string_literal: true

################################################################################
#
# Copyright (C) 2011 James Healy (jimmy@deefa.com)
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
  # A Hash-like object that can convert glyph names into a unicode codepoint.
  # The mapping is read from a data file on disk the first time it's needed.
  #
  class GlyphHash # :nodoc:
    @@by_codepoint_cache = nil #: Hash[Integer, Array[Symbol]] | nil
    @@by_name_cache = nil #: Hash[Symbol, Integer] | nil

    # An internal class for returning multiple pieces of data and keep sorbet happy
    class ReturnData
      #: Hash[Symbol, Integer]
      attr_reader :by_name

      #: Hash[Integer, Array[Symbol]]
      attr_reader :by_codepoint

      #:(Hash[Symbol, Integer], Hash[Integer, Array[Symbol]]) -> void
      def initialize(by_name, by_codepoint)
        @by_name = by_name
        @by_codepoint = by_codepoint
      end
    end

    #: () -> void
    def initialize
      @@by_codepoint_cache ||= nil
      @@by_name_cache ||= nil

      # only parse the glyph list once, and cache the results (for performance)
      if @@by_codepoint_cache != nil && @@by_name_cache != nil
        @by_name      = @@by_name_cache #: Hash[Symbol, Integer]
        @by_codepoint = @@by_codepoint_cache #: Hash[Integer, Array[Symbol]]
      else
        res = load_adobe_glyph_mapping
        @by_name      = @@by_name_cache ||= res.by_name
        @by_codepoint = @@by_codepoint_cache ||= res.by_codepoint
      end
    end

    # attempt to convert a PDF Name to a unicode codepoint. Returns nil
    # if no conversion is possible.
    #
    #   h = GlyphHash.new
    #
    #   h.name_to_unicode(:A)
    #   => 65
    #
    #   h.name_to_unicode(:Euro)
    #   => 8364
    #
    #   h.name_to_unicode(:X4A)
    #   => 74
    #
    #   h.name_to_unicode(:G30)
    #   => 48
    #
    #   h.name_to_unicode(:34)
    #   => 34
    #
    #: (Symbol | nil) -> (Integer | nil)
    def name_to_unicode(name)
      return nil unless name.is_a?(Symbol)

      name = name.to_s.gsub('_', '').intern
      str = name.to_s

      if @by_name.has_key?(name)
        @by_name[name]
      elsif str.match(/\AX[0-9a-fA-F]{2,4}\Z/)
        "0x#{str[1,4]}".hex
      elsif str.match(/\Auni[A-F\d]{4}\Z/)
        "0x#{str[3,4]}".hex
      elsif str.match(/\Au[A-F\d]{4,6}\Z/)
        "0x#{str[1,6]}".hex
      elsif str.match(/\A[A-Za-z]\d{1,5}\Z/)
        str[1,5].to_i
      elsif str.match(/\A[A-Za-z]{2}\d{2,5}\Z/)
        str[2,5].to_i
      else
        nil
      end
    end

    # attempt to convert a Unicode code point to the equivilant PDF Name. Returns nil
    # if no conversion is possible.
    #
    #   h = GlyphHash.new
    #
    #   h.unicode_to_name(65)
    #   => [:A]
    #
    #   h.unicode_to_name(8364)
    #   => [:Euro]
    #
    #   h.unicode_to_name(34)
    #   => [:34]
    #
    #: (Integer) -> Array[Symbol]
    def unicode_to_name(codepoint)
      @by_codepoint[codepoint.to_i] || []
    end

    private

    # returns a hash that maps glyph names to unicode codepoints. The mapping is based on
    # a text file supplied by Adobe at:
    # https://github.com/adobe-type-tools/agl-aglfn
    #: () -> ReturnData
    def load_adobe_glyph_mapping
      keyed_by_name      = {} #: Hash[Symbol, Integer]
      keyed_by_codepoint = {} #: Hash[Integer, Array[Symbol]]

      paths = [
        File.dirname(__FILE__) + "/glyphlist.txt",
        File.dirname(__FILE__) + "/glyphlist-zapfdingbats.txt",
      ]
      paths.each do |path|
        File.open(path, "r:BINARY") do |f|
          f.each do |l|
            _m, name, code = *l.match(/([0-9A-Za-z]+);([0-9A-F]{4})/)
            if name && code
              cp = "0x#{code}".hex
              keyed_by_name[name.to_sym]   = cp
              keyed_by_codepoint[cp]     ||= []
              arr = keyed_by_codepoint[cp]
              if arr
                arr.push(name.to_sym)
              end
            end
          end
        end
      end

      ReturnData.new(keyed_by_name.freeze, keyed_by_codepoint.freeze)
    end

  end
end
