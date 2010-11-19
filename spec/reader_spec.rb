# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader, "file class method" do

  before(:each) do
    @receiver = PDF::Reader::RegisterReceiver.new
    @filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
  end

  it "should parse all aspects of a PDF file by default" do
    PDF::Reader.file(@filename, @receiver)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(1)
  end

  it "should not provide raw text callbacks by default" do
    PDF::Reader.file(@filename, @receiver)
    @receiver.count(:show_text_with_positioning).should eql(1)
    @receiver.count(:show_text_with_positioning_raw).should eql(0)
  end

  it "should provide raw text callbacks if requested" do
    PDF::Reader.file(@filename, @receiver, :raw_text => true)
    @receiver.count(:show_text_with_positioning).should eql(1)
    @receiver.count(:show_text_with_positioning_raw).should eql(1)
  end

  it "should not parse metadata if requested" do
    PDF::Reader.file(@filename, @receiver, :metadata => false)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(0)
  end

  it "should not parse page content if requested" do
    PDF::Reader.file(@filename, @receiver, :pages => false)
    @receiver.count(:begin_document).should eql(0)
    @receiver.count(:metadata).should eql(1)
  end

  it "should raise an exception if an encrypted file is opened" do
    filename = File.dirname(__FILE__) + "/data/difference_table_encrypted.pdf"
    lambda {
      PDF::Reader.file(filename, @receiver)
    }.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end
end

describe PDF::Reader, "string class method" do

  before(:each) do
    @receiver = PDF::Reader::RegisterReceiver.new
    filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
    if File.respond_to?(:binread)
      @data = File.binread(filename)
    else
      @data = File.open(filename, "r") { |f| f.read }
    end
  end

  it "should parse all aspects of a PDF file by default" do
    PDF::Reader.string(@data, @receiver)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(1)
  end

  it "should not provide raw text callbacks by default" do
    PDF::Reader.string(@data, @receiver)
    @receiver.count(:show_text_with_positioning).should eql(1)
    @receiver.count(:show_text_with_positioning_raw).should eql(0)
  end

  it "should provide raw text callbacks if requested" do
    PDF::Reader.string(@data, @receiver, :raw_text => true)
    @receiver.count(:show_text_with_positioning).should eql(1)
    @receiver.count(:show_text_with_positioning_raw).should eql(1)
  end

  it "should parse not parse metadata if requested" do
    PDF::Reader.string(@data, @receiver, :metadata => false)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(0)
  end

  it "should parse not parse page content if requested" do
    PDF::Reader.string(@data, @receiver, :pages => false)
    @receiver.count(:begin_document).should eql(0)
    @receiver.count(:metadata).should eql(1)
  end

  it "should raise an exception if an encrypted file is opened" do
    filename = File.dirname(__FILE__) + "/data/difference_table_encrypted.pdf"
    if File.respond_to?(:binread)
      @data = File.binread(filename)
    else
      @data = File.open(filename, "r") { |f| f.read }
    end
    lambda {
      PDF::Reader.string(@data, @receiver)
    }.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end
end

describe PDF::Reader, "object_file class method" do
  before(:each) do
    @filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
  end

  it "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_file(@filename, 7, 0).should eql(515)
  end

  it "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_file(@filename, 7).should eql(515)
  end
end

describe PDF::Reader, "object_string class method" do

  before(:each) do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
    if File.respond_to?(:binread)
      @data = File.binread(filename)
    else
      @data = File.open(filename, "r") { |f| f.read }
    end
  end

  it "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_string(@data, 7, 0).should eql(515)
  end

  it "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_string(@data, 7).should eql(515)
  end

end
