# coding: utf-8

module PDF
  class Reader

    # a new way of browsing PDF content.
    #
    # A PDF file more or less a page based ile format. There is some data
    # associated with the document (metadata, bookmarks, etc) but all visible
    # content is stored under a Page object.
    #
    # == Basic Usage
    #
    #   browser = PDF::Reader::Browser.new("somefile.pdf")
    #   puts browser.pdf_version
    #   puts browser.metadata
    #   puts browser.xml_metadata
    #
    #   browser.pages.each do |page|
    #     puts page.fonts
    #     puts page.images
    #     puts page.text
    #   end
    #
    class Browser

    end
  end
end
