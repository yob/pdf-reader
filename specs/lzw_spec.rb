# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

context PDF::Reader::LZW do
  it "should correctly decode a lzw compress string" do
    content = %w{ 80 0B 60 50 22 0C 0C 85 01 }.map { |byte|
      byte.to_i(16)
    }

    PDF::Reader::LZW.decode(content).should == '-----A---B'
  end
end
