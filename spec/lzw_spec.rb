# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::LZW do
  it "should correctly decode a lzw compress string" do
    content = %w{ 80 0B 60 50 22 0C 0C 85 01 }.map { |byte|
      byte.to_i(16)
    }.pack("C*")

    PDF::Reader::LZW.decode(content).should == '-----A---B'
  end
end
