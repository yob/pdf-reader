# coding: utf-8

require "spec_helper"

describe Marron::LZW do
  it "should correctly decode a lzw compress string" do
    content = %w{ 80 0B 60 50 22 0C 0C 85 01 }.map { |byte|
      byte.to_i(16)
    }.pack("C*")

    Marron::LZW.decode(content).should == '-----A---B'
  end
end
