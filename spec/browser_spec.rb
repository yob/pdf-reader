# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader, "open()" do

  it "should pass a reader instance to a block" do
    filename = pdf_spec_file("cairo-basic")
    PDF::Reader.open(filename) do |reader|
      reader.pdf_version.should eql(1.4)
    end
  end
end

describe PDF::Reader, "with cairo-basic.pdf" do

  before(:each) do
    filename = pdf_spec_file("cairo-basic")
    @browser = PDF::Reader.new(filename)
  end

  it "should return the correct pdf_version" do
    @browser.pdf_version.should eql(1.4)
  end

  it "should return the correct page_count" do
    @browser.page_count.should eql(2)
  end

  it "should return the correct info hash" do
    info    = @browser.info

    info.size.should eql(2)
    info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
    info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
  end

  it "should return the nil for metadata" do
    @browser.metadata.should be_nil
  end

  it "should return an array of Pages from pages()" do
    @browser.pages.should be_a_kind_of(Array)
    @browser.pages.size.should eql(@browser.page_count)
    @browser.pages.each do |page|
      page.should be_a_kind_of(PDF::Reader::Page)
    end
  end

  it "should return a single Page from page()" do
    @browser.page(1).should be_a_kind_of(PDF::Reader::Page)
  end

end

describe PDF::Reader, "with no_text_spaces.pdf" do

  before(:each) do
    filename = pdf_spec_file("no_text_spaces")
    @browser = PDF::Reader.new(filename)
  end

  it "should return the correct pdf_version" do
    @browser.pdf_version.should eql(1.4)
  end

  it "should return the correct page_count" do
    @browser.page_count.should eql(6)
  end

  it "should return the correct info hash" do
    info    = @browser.info

    info.size.should eql(9)
  end

  it "should return the nil for metadata" do
    @browser.metadata.should be_a_kind_of(String)
    @browser.metadata.should include("<x:xmpmeta")
  end

  it "should return an array of Pages from pages()" do
    @browser.pages.should be_a_kind_of(Array)
    @browser.pages.size.should eql(@browser.page_count)
    @browser.pages.each do |page|
      page.should be_a_kind_of(PDF::Reader::Page)
    end
  end

  it "should return a single Page from page()" do
    @browser.page(1).should be_a_kind_of(PDF::Reader::Page)
  end
end
