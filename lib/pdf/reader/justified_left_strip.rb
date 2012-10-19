# coding: utf-8

class PDF::Reader
  # given a multi-line string with varied amounts of whitespace on the left
  # hand side, trim the whitespace evenly so that the left-most text has no
  # whitespace at all.
  #
  # eg this:
  #
  #     |  one
  #     |   two
  #     |   three
  #
  # will become this:
  #
  #     |one
  #     | two
  #     | three
  #
  class JustifiedLeftStrip
    def initialize(string)
      @string       = string
      @split_string = string.split("\n")
      @trim_amount  = @split_string.map { |line|
        line.index(/[^\s]/)
      }.sort.first
    end

    def lstrip
      if @trim_amount == 0
        @string.dup
      else
        @split_string.map { |line|
          line[@trim_amount, line.size]
        }.join("\n")
      end
    end
  end
end
