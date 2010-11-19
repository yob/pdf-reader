# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Filter do

  it "should inflate a RFC1950 (zlib) deflated stream correctly"
  it "should inflate a raw RFC1951 deflated stream correctly"
  it "should inflate a deflated stream with predictors correctly" do
    filter = PDF::Reader::Filter.new(:FlateDecode, :Columns => 5, :Predictor => 12)
    if File.respond_to?(:binread)
      deflated_data    = File.binread(File.dirname(__FILE__) + "/data/deflated_with_predictors.dat")
      depredicted_data = File.binread(File.dirname(__FILE__) + "/data/deflated_with_predictors_result.dat")
    else
      deflated_data    = File.open(File.dirname(__FILE__) + "/data/deflated_with_predictors.dat","r") { |f| f.read }
      depredicted_data = File.open(File.dirname(__FILE__) + "/data/deflated_with_predictors_result.dat","r") { |f| f.read }
    end
    filter.filter(deflated_data).should eql(depredicted_data)
  end

  it "should filter a lzw stream with no predictors correctly" do
    filter = PDF::Reader::Filter.new(:LZWDecode)
    if File.respond_to?(:binread)
      compressed_data   = File.binread(File.dirname(__FILE__) + "/data/lzw_compressed.dat")
      decompressed_data = File.binread(File.dirname(__FILE__) + "/data/lzw_decompressed.dat")
    else
      compressed_data   = File.open(File.dirname(__FILE__) + "/data/lzw_compressed.dat","r") { |f| f.read }
      decompressed_data = File.open(File.dirname(__FILE__) + "/data/lzw_decompressed.dat","r") { |f| f.read }
    end
    filter.filter(compressed_data).should eql(decompressed_data)
  end

  it "should raise an exception on LZW compressed streams that use predictors" do
    if File.respond_to?(:binread)
      compressed_data   = File.binread(File.dirname(__FILE__) + "/data/lzw_compressed.dat")
    else
      compressed_data   = File.open(File.dirname(__FILE__) + "/data/lzw_compressed.dat","r") { |f| f.read }
    end

    filter = PDF::Reader::Filter.new(:LZWDecode, :Predictor => 2)
    lambda {
      filter.filter(compressed_data)
    }.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end

  it "should filter a ASCII85 stream correctly" do
    filter = PDF::Reader::Filter.new(:ASCII85Decode)
    encoded_data = Ascii85::encode("Ruby")
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCII85 stream missing <~ correctly" do
    filter = PDF::Reader::Filter.new(:ASCII85Decode)
    encoded_data = Ascii85::encode("Ruby")[2,100]
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCIIHex stream correctly" do
    filter = PDF::Reader::Filter.new(:ASCIIHexDecode)
    encoded_data = "<52756279>"
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCIIHex stream missing delimiters" do
    filter = PDF::Reader::Filter.new(:ASCIIHexDecode)
    encoded_data = "52756279"
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCIIHex stream with an odd number of nibbles" do
    filter = PDF::Reader::Filter.new(:ASCIIHexDecode)
    encoded_data = "5275627"
    filter.filter(encoded_data).should eql("Rubp")
  end

end
