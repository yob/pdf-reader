# coding: utf-8

module PDF
  class Reader

    # A new way of browsing PDF content.
    #
    # PDF is a page based file format. There is some data associated with the
    # document (metadata, bookmarks, etc) but all visible content is stored 
    # under a Page object.
    #
    # In most use cases for extracting and examining to contents of a PDF, it
    # makes sense to traverse the information using page based iteration.
    #
    # == File Metadata
    #
    #   browser = PDF::Reader::Browser.new("somefile.pdf")
    #
    #   puts browser.pdf_version
    #   puts browser.info
    #   puts browser.metadata
    #   puts browser.page_count
    #
    # == Iterating over page content
    #
    #   browser = PDF::Reader::Browser.new("somefile.pdf")
    #
    #   browser.pages.each do |page|
    #     puts page.fonts
    #     puts page.images
    #     puts page.text
    #   end
    #
    # == Extracting all text
    #
    #   browser = PDF::Reader::Browser.new("somefile.pdf")
    #
    #   browser.pages.map(&:text)
    #
    # == Extracting content from a single page
    #
    #   browser = PDF::Reader::Browser.new("somefile.pdf")
    #
    #   page = browser.page(1)
    #   puts page.fonts
    #   puts page.images
    #   puts page.text
    #
    # == Low level callbacks (ala current version of PDF::Reader)
    #
    #   browser = PDF::Reader::Browser.new("somefile.pdf")
    #
    #   page = browser.page(1)
    #   page.walk(receiver)
    #
    class Browser

      attr_reader :page_count, :pdf_version, :info, :metadata

      def initialize(input)
        @ohash = PDF::Reader::ObjectHash.new(input)
        @page_count  = get_page_count
        @pdf_version = @ohash.pdf_version
        @info        = @ohash.object(@ohash.trailer[:Info])
      end

      def pages
        (1..@page_count).map { |num|
          PDF::Reader::BrowserPage.new(@ohash, num)
        }
      end

      def page(num)
        num = num.to_i
        raise ArgumentError, "valid pages are 1 .. #{@page_count}" if num < 1 || num > @page_count
        PDF::Reader::BrowserPage.new(@ohash, num)
      end

      private

      def ohash
        @ohash
      end

      def root
        root ||= @ohash.object(@ohash.trailer[:Root])
      end

      def get_page_count
        pages = @ohash.object(root[:Pages])
        pages[:Count]
      end

    end
  end
end
