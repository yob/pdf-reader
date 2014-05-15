# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader, "file class method" do

  before(:each) do
    @receiver = PDF::Reader::RegisterReceiver.new
    @filename = pdf_spec_file("cairo-unicode-short")
  end

  it "should parse all aspects of a PDF file by default" do
    PDF::Reader.file(@filename, @receiver)
    expect(@receiver.count(:begin_document)).to eql(1)
    expect(@receiver.count(:metadata)).to eql(1)
  end

  it "should not provide raw text callbacks by default" do
    PDF::Reader.file(@filename, @receiver)
    expect(@receiver.count(:show_text_with_positioning)).to eql(1)
    expect(@receiver.count(:show_text_with_positioning_raw)).to eql(0)
  end

  it "should provide raw text callbacks if requested" do
    PDF::Reader.file(@filename, @receiver, :raw_text => true)
    expect(@receiver.count(:show_text_with_positioning)).to eql(1)
    expect(@receiver.count(:show_text_with_positioning_raw)).to eql(1)
  end

  it "should not parse metadata if requested" do
    PDF::Reader.file(@filename, @receiver, :metadata => false)
    expect(@receiver.count(:begin_document)).to eql(1)
    expect(@receiver.count(:metadata)).to eql(0)
  end

  it "should not parse page content if requested" do
    PDF::Reader.file(@filename, @receiver, :pages => false)
    expect(@receiver.count(:begin_document)).to eql(0)
    expect(@receiver.count(:metadata)).to eql(1)
  end

end

describe PDF::Reader, "string class method" do

  let!(:receiver) { PDF::Reader::RegisterReceiver.new }
  let!(:data)     { binread(pdf_spec_file("cairo-unicode-short")) }

  it "should parse all aspects of a PDF file by default" do
    PDF::Reader.string(data, receiver)
    expect(receiver.count(:begin_document)).to eql(1)
    expect(receiver.count(:metadata)).to eql(1)
  end

  it "should not provide raw text callbacks by default" do
    PDF::Reader.string(data, receiver)
    expect(receiver.count(:show_text_with_positioning)).to eql(1)
    expect(receiver.count(:show_text_with_positioning_raw)).to eql(0)
  end

  it "should provide raw text callbacks if requested" do
    PDF::Reader.string(data, receiver, :raw_text => true)
    expect(receiver.count(:show_text_with_positioning)).to eql(1)
    expect(receiver.count(:show_text_with_positioning_raw)).to eql(1)
  end

  it "should parse not parse metadata if requested" do
    PDF::Reader.string(data, receiver, :metadata => false)
    expect(receiver.count(:begin_document)).to eql(1)
    expect(receiver.count(:metadata)).to eql(0)
  end

  it "should parse not parse page content if requested" do
    PDF::Reader.string(data, receiver, :pages => false)
    expect(receiver.count(:begin_document)).to eql(0)
    expect(receiver.count(:metadata)).to eql(1)
  end

end

describe PDF::Reader, "object_file class method" do
  before(:each) do
    @filename = pdf_spec_file("cairo-unicode-short")
  end

  it "should extract an object from string containing a full PDF file" do
    expect(PDF::Reader.object_file(@filename, 7, 0)).to eql(515)
  end

  it "should extract an object from string containing a full PDF file" do
    expect(PDF::Reader.object_file(@filename, 7)).to eql(515)
  end
end

describe PDF::Reader, "object_string class method" do

  let(:data) { binread(pdf_spec_file("cairo-unicode-short")) }

  it "should extract an object from string containing a full PDF file" do
    expect(PDF::Reader.object_string(data, 7, 0)).to eql(515)
  end

  it "should extract an object from string containing a full PDF file" do
    expect(PDF::Reader.object_string(data, 7)).to eql(515)
  end

end
