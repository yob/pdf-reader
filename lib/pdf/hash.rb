# coding: utf-8

module PDF
  class Hash < PDF::Reader::XRef #nodoc
    def initialize(input)
      warn "DEPRECATION NOTICE: PDF::Hash has been deprecated, use PDF::Reader::XRef instead"
      super
    end
  end
end
