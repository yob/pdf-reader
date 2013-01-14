# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::FileWriter, "to_s method" do
  context "re-saving an existing file with no changes" do
    let!(:filename) { pdf_spec_file("adobe_sample") }
    let!(:objects)  { PDF::Reader::ObjectHash.new(filename) }
    let!(:writer)   { PDF::Reader::FileWriter.new(objects) }

    it "should return a string the begins with the PDF marker" do
      writer.to_s[0,8].should == "%PDF-1.2"
    end

    it "should return a string that ends with the EOF marker" do
      writer.to_s[-6,6].should == "%%EOF\r"
    end
  end

  context "re-saving an existing file with the producer changed" do
    let!(:filename) { pdf_spec_file("adobe_sample") }
    let!(:objects)  { PDF::Reader::ObjectHash.new(filename) }
    let!(:writer)   { PDF::Reader::FileWriter.new(objects) }

    before do
      info_ref = objects.trailer[:Info]
      info = objects.deref(info_ref)
      objects[info_ref] = info.merge(:Producer => "pdf-reader")
    end

    it "should return a string the begins with the PDF marker" do
      writer.to_s[0,8].should == "%PDF-1.2"
    end

    it "should return a string encoded in binary" do
      result = writer.to_s[-5,5]
      if result.respond_to?(:encoding)
        result.encoding.should == Encoding.find("binary")
      end
    end

    it "should append the changes objects to the end of the new file" do
      new_content = writer.to_s[378346,10000]
      new_content.should include("1 0 R")
    end

    it "should append an updated xref table to the end of the new file" do
      new_content = writer.to_s[378346,10000]
      new_content.should include("xref\n1 1\n0000378346 00000 n")
    end

    it "should append an updated trailer to the end of the new file" do
      new_content = writer.to_s[378346,10000]
      new_content.should include("trailer")
    end

    it "should include a pointer to the previous xref table" do
      new_content = writer.to_s[378346,10000]
      new_content.should include("Prev 173")
    end

    it "should include a pointer to the new xref table at the end of the file" do
      new_content = writer.to_s[378346,10000]
      new_content.should include("startxref\n378882")
    end

    it "should return a string that ends with the EOF marker" do
      writer.to_s[-5,5].should == "%%EOF"
    end
  end
end
