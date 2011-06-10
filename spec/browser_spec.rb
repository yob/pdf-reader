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

  it "should return the correct metadata" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    info    = browser.info

    info.size.should eql(2)
    info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
    info[:Producer].should eql("cairo 1.4.6 (http://cairographics.org)")
  end

end
