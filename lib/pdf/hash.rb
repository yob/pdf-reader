# coding: utf-8

module PDF
  class Hash < ::PDF::Reader::ObjectHash # :nodoc:
    def initialize(input)
      warn "DEPRECATION NOTICE: PDF::Hash has been deprecated, use PDF::Reader::ObjectHash instead"
      super
    end

    def version
      warn "DEPRECATION NOTICE: PDF::Hash#version has been deprecated, use PDF::Reader::ObjectHash#pdf_version instead"
      pdf_version
    end
  end
end
