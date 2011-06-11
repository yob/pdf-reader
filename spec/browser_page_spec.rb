# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::BrowserPage, "fonts()" do

  it "should return a hash with the correct size from cairo-basic.pdf page 1" do
    @browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.fonts.should      be_a_kind_of(Hash)
    @page.fonts.size.should eql(1)
    @page.fonts.keys.should eql([:"CairoFont-0-0"])
  end
end

describe PDF::Reader::BrowserPage, "xobjects()" do
  it "should return a hash with the correct size from cairo-basic.pdf page 1" do
    @browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.xobjects.should be_a_kind_of(Hash)
    @page.xobjects.should be_empty
  end
end

describe PDF::Reader::BrowserPage, "xobjects()" do
  it "should return a string from raw_content() from cairo-basic.pdf page 1" do
    @browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.raw_content.should be_a_kind_of(String)
  end
end

describe PDF::Reader::BrowserPage, "text()" do
  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    @page.text.should eql("Hello James")
  end
end

describe PDF::Reader::BrowserPage, "walk()" do

  it "should run callbacks while walking content stream from cairo-basic.pdf page 1" do
    @browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)

    receiver = PDF::Reader::RegisterReceiver.new
    @page.walk(receiver)

    callbacks = receiver.callbacks.map { |cb| cb[:name] }

    callbacks.size.should eql(15)
    callbacks.first.should eql(:save_graphics_state)
  end

end
