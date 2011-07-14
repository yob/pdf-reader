# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Page, "fonts()" do

  it "should return a hash with the correct size from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.fonts.should      be_a_kind_of(Hash)
    @page.fonts.size.should eql(1)
    @page.fonts.keys.should eql([:"CairoFont-0-0"])
  end
end

describe PDF::Reader::Page, "raw_content()" do
  it "should return a string from raw_content() from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.raw_content.should be_a_kind_of(String)
  end
end

describe PDF::Reader::Page, "text()" do
  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.text.should eql("Hello James")
  end

  it "should return the text content from cairo-multiline.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-multiline.pdf")
    @page    = @browser.page(1)

    @page.text.should eql("Hello World\nFrom James")
  end
end

describe PDF::Reader::Page, "walk()" do

  it "should call the special page= callback while walking content stream from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    receiver = PDF::Reader::RegisterReceiver.new
    @page.walk(receiver)

    callbacks = receiver.callbacks.map { |cb| cb[:name] }

    callbacks.first.should eql(:page=)
  end

  it "should run callbacks while walking content stream from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    receiver = PDF::Reader::RegisterReceiver.new
    @page.walk(receiver)

    callbacks = receiver.callbacks.map { |cb| cb[:name] }

    callbacks.size.should eql(16)
    callbacks[0].should eql(:page=)
    callbacks[1].should eql(:save_graphics_state)
  end

  it "should run callbacks on multiple receivers while walking content stream from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    receiver_one = PDF::Reader::RegisterReceiver.new
    receiver_two = PDF::Reader::RegisterReceiver.new
    @page.walk(receiver_one, receiver_two)

    callbacks = receiver_one.callbacks.map { |cb| cb[:name] }

    callbacks.size.should eql(16)
    callbacks.first.should eql(:page=)

    callbacks = receiver_two.callbacks.map { |cb| cb[:name] }

    callbacks.size.should eql(16)
    callbacks.first.should eql(:page=)
  end

end

describe PDF::Reader::Page, "number()" do

  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.number.should eql(1)
  end

end

describe PDF::Reader::Page, "number()" do

  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.number.should eql(1)
  end

end

describe PDF::Reader::Page, "attributes()" do

  it "should contain attributes from the Page object" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/inherited_page_attributes.pdf")
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:Resources].should      be_a_kind_of(Hash)
    attribs[:Resources].size.should eql(2)
  end

  it "should contain inherited attributes" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/inherited_page_attributes.pdf")
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:MediaBox].should eql([0.0, 0.0, 595.276, 841.89])
  end

  it "should allow Page to override inherited attributes" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/override_inherited_attributes.pdf")
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:MediaBox].should eql([0, 0, 200, 200])
  end

end

describe PDF::Reader::Page, "resources()" do

  it "should contain resources from the Page object" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/inherited_page_attributes.pdf")
    @page    = @browser.page(1)

    @page.resources.should      be_a_kind_of(Hash)
    @page.resources.size.should eql(2)
  end

  it "should contain inherited resources" do
    @browser = PDF::Reader.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.resources.should      be_a_kind_of(Hash)
    @page.resources.size.should eql(2)
  end

end
