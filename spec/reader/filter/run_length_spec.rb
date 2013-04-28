# coding: utf-8

require "spec_helper"

describe Marron::Filter::RunLength do
  it "should filter a RunLengthDecode stream correctly" do
    filter = Marron::Filter::RunLength.new
    encoded_data = [2, "\x00"*3, 255, "\x01", 128].pack('Ca*Ca*C')
    filter.filter(encoded_data).should eql("\x00\x00\x00\x01\x01")
  end
end
