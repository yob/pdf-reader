# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader do
  let(:cairo_basic)   { pdf_spec_file("cairo-basic")}
  let(:oo3)           { pdf_spec_file("oo3")}
  let(:no_text_spaces) { pdf_spec_file("no_text_spaces")}

  describe "open() class method" do

    it "should pass a reader instance to a block" do
      PDF::Reader.open(cairo_basic) do |reader|
        expect(reader.pdf_version).to eql(1.4)
      end
    end
  end

  describe "pdf_version()" do
    it "should return the correct pdf_version" do
      expect(PDF::Reader.new(cairo_basic).pdf_version).to eql(1.4)
    end

    it "should return the correct pdf_version" do
      expect(PDF::Reader.new(no_text_spaces).pdf_version).to eql(1.4)
    end
  end

  describe "page_count()" do
    context "with cairo-basic" do
      it "should return the correct page_count" do
        expect(PDF::Reader.new(cairo_basic).page_count).to eql(2)
      end
    end

    context "with no_text_spaces" do
      it "should return the correct page_count" do
        expect(PDF::Reader.new(no_text_spaces).page_count).to eql(6)
      end
    end

    context "with indirect_page_count" do
      it "should return the correct page_count" do
        expect(PDF::Reader.new(pdf_spec_file("indirect_page_count")).page_count).to eql(1)
      end
    end
  end

  describe "info()" do
    it "should return the correct info hash from cairo-basic" do
      info = PDF::Reader.new(cairo_basic).info

      expect(info.size).to eql(2)
      expect(info[:Creator]).to eql("cairo 1.4.6 (http://cairographics.org)")
      expect(info[:Producer]).to eql("cairo 1.4.6 (http://cairographics.org)")
    end

    it "should return the correct info hash from no_text_spaces" do
      info = PDF::Reader.new(no_text_spaces).info

      expect(info.size).to eql(9)
    end

    it "should return the correct info hash from a file with utf-16 encoded info" do
      info = PDF::Reader.new(oo3).info

      expect(info.size).to eql(3)
      expect(info[:Creator]).to  eql "Writer"
      expect(info[:Producer]).to eql "OpenOffice.org 3.2"
      expect(info[:CreationDate]).to eql "D:20101113071546-06'00'"
    end

    it "should return an info hash with strings marked as UTF-8" do
      info = PDF::Reader.new(oo3).info

      expect(info[:Creator].encoding).to      eql Encoding::UTF_8
      expect(info[:Producer].encoding).to     eql Encoding::UTF_8
      expect(info[:CreationDate].encoding).to eql Encoding::UTF_8
    end
  end

  describe "metadata()" do
    it "should return nil metadata from cairo-basic" do
      expect(PDF::Reader.new(cairo_basic).metadata).to be_nil
    end

    it "should return the correct metadata from no_text_spaces" do
      metadata = PDF::Reader.new(no_text_spaces).metadata

      expect(metadata).to be_a_kind_of(String)
      expect(metadata).to include("<x:xmpmeta")
    end

    it "should return the metadata string marked as UTF-8" do
      metadata = PDF::Reader.new(no_text_spaces).metadata

      expect(metadata.encoding).to eql Encoding::UTF_8
    end
  end

  describe "pages()" do
    it "should return an array of pages from cairo-basic" do
      pages = PDF::Reader.new(cairo_basic).pages

      expect(pages).to be_a_kind_of(Array)
      expect(pages.size).to eql(2)
      pages.each do |page|
        expect(page).to be_a_kind_of(PDF::Reader::Page)
      end
    end

    it "should return an array of pages from no_text_spaces" do
      pages = PDF::Reader.new(no_text_spaces).pages

      expect(pages).to be_a_kind_of(Array)
      expect(pages.size).to eql(6)
      pages.each do |page|
        expect(page).to be_a_kind_of(PDF::Reader::Page)
      end
    end
  end

  describe "page()" do
    it "should return a single page from cairo-basic" do
      expect(PDF::Reader.new(cairo_basic).page(1)).to be_a_kind_of(PDF::Reader::Page)
    end

    it "should return a single page from no_text_spaces" do
      expect(PDF::Reader.new(no_text_spaces).page(1)).to be_a_kind_of(PDF::Reader::Page)
    end
  end

end
