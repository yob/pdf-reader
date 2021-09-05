# typed: false
# coding: utf-8

describe PDF::Reader::PageTextReceiver do

  it "returns the text content from cairo-basic.pdf page 1" do
    @reader   = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    expect(@receiver.content).to eql("Hello James")
  end

  it "returns the text content from cairo-multiline.pdf page 1" do
    @reader   = PDF::Reader.new(pdf_spec_file("cairo-multiline"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    expect(@receiver.content).to match(/\AHello World$.+^From James\Z/m)
  end

  it "returns the text content from Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("form_xobject"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    expect(@receiver.content).to eql("James Healy")
  end

  it "returns merged text content from the regular page and a Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("form_xobject_more"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    expect(@receiver.content).to match(/\AJames Healy$.+^Some regular content\Z/m)
  end

  it "parses a page with nested Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("nested_form_xobject"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    expect(@receiver.content).to eql("")
  end

  it "parses a page with nested Form XObjects" do
    @reader   = PDF::Reader.new(pdf_spec_file("nested_form_xobject_another"))
    @page     = @reader.page(1)
    @receiver = PDF::Reader::PageTextReceiver.new

    @page.walk(@receiver)

    expect(@receiver.content).to match(/\Aone$.+^two$.+^three$.+^four\Z/m)
  end

end
