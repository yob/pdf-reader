# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Browser, "with cairo-basic.pdf" do

  it "should return the correct pdf_version" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    browser.pdf_version.should eql(1.4)
  end

  it "should return the correct page_count" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    browser.page_count.should eql(2)
  end

  it "should return the correct info hash" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    info    = browser.info

    info.size.should eql(2)
    info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
    info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
  end

  it "should return the nil for metadata" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    browser.metadata.should be_nil
  end

  it "should return an array of BrowserPages from pages()" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    browser.pages.should be_a_kind_of(Array)
    browser.pages.size.should eql(browser.page_count)
    browser.pages.each do |page|
      page.should be_a_kind_of(PDF::Reader::BrowserPage)
    end
  end

  it "should return a single BrowserPage from page()" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    browser.page(1).should be_a_kind_of(PDF::Reader::BrowserPage)
  end

end

describe PDF::Reader::Browser, "with no_text_spaces.pdf" do

  it "should return the correct pdf_version" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/no_text_spaces.pdf")
    browser.pdf_version.should eql(1.4)
  end

  it "should return the correct page_count" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/no_text_spaces.pdf")
    browser.page_count.should eql(6)
  end

  it "should return the correct info hash" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/no_text_spaces.pdf")
    info    = browser.info

    info.size.should eql(9)
  end

  it "should return the nil for metadata" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/no_text_spaces.pdf")
    browser.metadata.should be_a_kind_of(String)
    browser.metadata.should include("<x:xmpmeta")
  end

  it "should return an array of BrowserPages from pages()" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/no_text_spaces.pdf")
    browser.pages.should be_a_kind_of(Array)
    browser.pages.size.should eql(browser.page_count)
    browser.pages.each do |page|
      page.should be_a_kind_of(PDF::Reader::BrowserPage)
    end
  end

  it "should return a single BrowserPage from page()" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/no_text_spaces.pdf")
    browser.page(1).should be_a_kind_of(PDF::Reader::BrowserPage)
  end
end
