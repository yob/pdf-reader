# coding: utf-8
#

class PDF::Reader
  # A Hash-like object that wraps the array of glyph widths in a CID font
  # and gives us a nice way to query it for specific widths.
  #
  # there are two ways to calculate a cidfont_glyph_width, that are defined
  # in Section 9.7.4.3 PDF 32000-1:2008 pp 271, the differences are remarked
  # on below. because of these difference that may be contained within the
  # same array, it is a bit difficult to parse this array.
  class CidWidths
    extend Forwardable

    # Graphics State Operators
    def_delegators :@widths, :[], :fetch

    def initialize(default, array)
      @widths  = Hash.new(default)
      parse_array(array)
    end

    private

    def parse_array(array)
      first = -1
      last = -1
      width_spec = nil
      array.each { |element|
        if first < 0
          first = element
        elsif element.is_a?(Array)
          width_spec = element
        elsif last < 0
          last = element
        else
          width_spec = element
        end

        if last < 0 && width_spec
          # this is the form 10 [234 63 234 346 47 234] where width of index 10 is
          # 234, index 11 is 63, etc
          width_spec.each_with_index do |glyph_width, index|
            @widths[first + index] = glyph_width
          end
          first = -1
          width_spec = nil
        elsif last > 0 && width_spec != nil && width_spec > 0
          # this is the form 10 20 123 where all index between 10 and 20 have width 123
          (first..last).each do |index|
            @widths[index] = width_spec
          end
          first = -1
          last = -1
          width_spec = nil
        end
      }
    end
  end
end
