# coding: utf-8

class PDF::Reader

  class MetadataVisitor < AbstractVisitor

    def self.to_sym
      :metadata
    end

    def process
      # may be useful to some people
      callback(:pdf_version, ohash.pdf_version)

      # ye olde metadata
      callback(:metadata, [decoded_info]) if info?

      # new style xml metadata
      if root[:Metadata]
        stream = ohash.object(root[:Metadata])
        callback(:xml_metadata, stream.unfiltered_data)
      end

      # page count
      if pages?
        count = ohash.object(pages[:Count])
        callback(:page_count, count.to_i)
      end
    end

    private

    def decoded_info
      @decoded_info ||= decode_strings(info)
    end

  end
end
