# coding: utf-8

module PDF
  class Reader
    class BrowserPage
      def initialize(ohash, pagenum)
        @ohash, @pagenum = ohash, pagenum
        @page_obj = get_page_obj(pagenum)
      end

      def fonts
        resources[:Font] || {}
      end

      def xobjects
        resources[:XObject] || {}
      end

      # returns the raw content stream for this page. This is plumbing, nothing to
      # see unless you're a PDF nerd like me.
      #
      def raw_content
        contents = ohash.object(@page_obj[:Contents])
        [contents].flatten.compact.map { |obj|
          ohash.object(obj)
        }.map { |obj|
          obj.unfiltered_data
        }.join
      end

      private

      def ohash
        @ohash
      end

      def root
        root ||= ohash.object(@ohash.trailer[:Root])
      end

      def resources
        hash = {}
        page_with_ancestors.each do |obj|
          hash.merge!(obj[:Resources]) if obj[:Resources]
        end
        hash
      end

      def page_with_ancestors(obj = nil)
        obj = ohash.object(obj)
        if obj.nil?
          [@page_obj] + page_with_ancestors(@page_obj[:Parent])
        elsif obj[:Parent]
          [obj] + page_with_ancestors(obj[:Parent])
        else
          [obj]
        end
      end

      def get_page_obj(page_num)
        pages = ohash.object(root[:Pages])
        page_array = get_page_objects(pages).flatten
        ohash.object(page_array[page_num - 1])
      end

      # returns a nested array of objects for all pages in this PDF.
      #
      def get_page_objects(obj)
        obj = ohash.object(obj)
        if obj[:Type] == :Page
          obj
        elsif obj[:Type] == :Pages
          obj[:Kids].map { |kid| get_page_objects(kid) }
        end
      end

    end
  end
end
