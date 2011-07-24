# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::PageTextReceiver do

  it "should return the text content from cairo-basic.pdf page 1" do
    @reader   = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    @receiver.content.should eql("Hello James")
  end

  it "should return the text content from cairo-multiline.pdf page 1" do
    @reader   = PDF::Reader.new(pdf_spec_file("cairo-multiline"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    @receiver.content.should eql("Hello World\nFrom James")
  end

  it "should return the text content from Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("form_xobject"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    @receiver.content.should eql("James Healy")
  end
end
