# coding: utf-8

require "spec_helper"

describe Marron::Filter::AsciiHex do
  it "should filter a ASCIIHex stream correctly" do
    filter = Marron::Filter::AsciiHex.new
    encoded_data = "<52756279>"
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCIIHex stream missing delimiters" do
    filter = Marron::Filter::AsciiHex.new
    encoded_data = "52756279"
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCIIHex stream with an odd number of nibbles" do
    filter = Marron::Filter::AsciiHex.new
    encoded_data = "5275627"
    filter.filter(encoded_data).should eql("Rubp")
  end
end
