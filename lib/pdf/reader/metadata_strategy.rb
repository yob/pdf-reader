# coding: utf-8

class PDF::Reader

  class MetadataStrategy < AbstractStrategy # :nodoc:

    def self.to_sym
      :metadata
    end

    def process
      return false unless options[:metadata]

      # may be useful to some people
      callback(:pdf_version, ohash.pdf_version)

      # ye olde metadata
      callback(:metadata, [decoded_info]) if info?

      # new style xml metadata
      callback(:xml_metadata, [xml_metadata]) if xml_metadata?

      # page count
      if pages?
        count = ohash.object(pages[:Count])
        callback(:page_count, count.to_i)
      end
    end

    private

    def xml_metadata
      return @xml_metadata if defined?(@xml_metadata)

      if root[:Metadata].nil?
        @xml_metadata = nil
      else
        string = ohash.object(root[:Metadata]).unfiltered_data
        string.force_encoding("utf-8") if string.respond_to?(:force_encoding)
        @xml_metadata = string
      end
    end

    def xml_metadata?
      xml_metadata ? true : false
    end

    def decoded_info
      @decoded_info ||= decode_strings(info)
    end

  end
end
