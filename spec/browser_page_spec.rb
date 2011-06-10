# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::BrowserPage, "with cairo-basic.pdf" do

  before(:each) do
    @browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @page    = @browser.page(1)
  end

  it "should return a hash with the correct size from fonts()" do
    @page.fonts.should      be_a_kind_of(Hash)
    @page.fonts.size.should eql(1)
    @page.fonts.keys.should eql([:"CairoFont-0-0"])
  end

  it "should return a hash with the correct size from xobjects()" do
    @page.xobjects.should be_a_kind_of(Hash)
    @page.xobjects.should be_empty
  end

  it "should return a string from raw_content()" do
    @page.raw_content.should be_a_kind_of(String)
  end

  it "should return the text content of the page"

  it "should run callbacks while walking a page content stream" do
    class SpecReceiver
      def respond_to?(meth)
        true
      end

      def method_missing(meth, *args)
        puts "#{meth}: #{args}"
      end
    end
    @page.walk(SpecReceiver.new)
    puts @page.raw_content
  end

end
