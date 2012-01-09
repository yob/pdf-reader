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

  it "should return merged text content from the regular page and a Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("form_xobject_more"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    @receiver.content.should eql("James Healy\nSome regular content")
  end

  it "should correctly parse a page with nested Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("nested_form_xobject"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    @receiver.content.should eql("")
  end

  it "should correctly parse a page with nested Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("nested_form_xobject_another"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    @receiver.content.should eql("one\ntwo\nthree\nfour")
  end

  describe "##DEFAULT_GRAPHICS_STATE" do
    subject { PDF::Reader::PageTextReceiver::DEFAULT_GRAPHICS_STATE }

    context "when walking more than one document" do
      let!(:expect) { PDF::Reader::PageTextReceiver::DEFAULT_GRAPHICS_STATE.dup }
      before do
        2.times do
          page = PDF::Reader.new(pdf_spec_file("adobe_sample")).page(1)
          receiver = PDF::Reader::PageTextReceiver.new
          page.walk(receiver)
        end
      end
      it "should not mutate" do
        should eql(expect)
      end
    end

  end

end
