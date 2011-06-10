# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Browser, "with cairo-basic.pdf" do

  it "should return the correct pdf_version" do
    browser = PDF::Reader::Browser.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    browser.pdf_version.should eql(1.4)
  end

end
