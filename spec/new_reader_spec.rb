# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader do
  let(:cairo_basic)   { pdf_spec_file("cairo-basic")}
  let(:no_text_spaces) { pdf_spec_file("no_text_spaces")}

  describe "open() class method" do

    it "should pass a reader instance to a block" do
      PDF::Reader.open(cairo_basic) do |reader|
        reader.pdf_version.should eql(1.4)
      end
    end
  end

  describe "pdf_version()" do
    it "should return the correct pdf_version" do
      PDF::Reader.new(cairo_basic).pdf_version.should eql(1.4)
    end

    it "should return the correct pdf_version" do
      PDF::Reader.new(no_text_spaces).pdf_version.should eql(1.4)
    end
  end

  describe "page_count()" do
    it "should return the correct page_count" do
      PDF::Reader.new(cairo_basic).page_count.should eql(2)
    end

    it "should return the correct page_count" do
      PDF::Reader.new(no_text_spaces).page_count.should eql(6)
    end
  end

  describe "info()" do
    it "should return the correct info hash from cairo-basic" do
      info = PDF::Reader.new(cairo_basic).info

      info.size.should eql(2)
      info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
      info[:Creator].should eql("cairo 1.4.6 (http://cairographics.org)")
    end

    it "should return the correct info hash from no_text_spaces" do
      info = PDF::Reader.new(no_text_spaces).info

      info.size.should eql(9)
    end
  end

  describe "metadata()" do
    it "should return nil metadata from cairo-basic" do
      PDF::Reader.new(cairo_basic).metadata.should be_nil
    end

    it "should return the correct metadata from no_text_spaces" do
      metadata = PDF::Reader.new(no_text_spaces).metadata

      metadata.should be_a_kind_of(String)
      metadata.should include("<x:xmpmeta")
    end

  end

  describe "pages()" do
    it "should return an array of pages from cairo-basic" do
      pages = PDF::Reader.new(cairo_basic).pages

      pages.should be_a_kind_of(Array)
      pages.size.should eql(2)
      pages.each do |page|
        page.should be_a_kind_of(PDF::Reader::Page)
      end
    end

    it "should return an array of pages from no_text_spaces" do
      pages = PDF::Reader.new(no_text_spaces).pages

      pages.should be_a_kind_of(Array)
      pages.size.should eql(6)
      pages.each do |page|
        page.should be_a_kind_of(PDF::Reader::Page)
      end
    end
  end

  describe "page()" do
    it "should return a single page from cairo-basic" do
      PDF::Reader.new(cairo_basic).page(1).should be_a_kind_of(PDF::Reader::Page)
    end

    it "should return a single page from no_text_spaces" do
      PDF::Reader.new(no_text_spaces).page(1).should be_a_kind_of(PDF::Reader::Page)
    end
  end

end
