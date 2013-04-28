# coding: utf-8

require "spec_helper"

describe Marron::Filter::Null do
  it "returns the data unchanged" do
    filter = Marron::Filter::Null.new
    filter.filter("\x00").should eql("\x00")
  end
end
