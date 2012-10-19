# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::JustifiedLeftStrip, "#lstrip" do
  context "with an empty string" do
    subject { PDF::Reader::JustifiedLeftStrip.new("")}

    it "should return an identical string" do
      subject.lstrip.should == ""
    end
  end

  context "with a string that has no LHS whitespace" do
    subject { PDF::Reader::JustifiedLeftStrip.new("one\ntwo\nthree")}

    it "should return an identical string" do
      subject.lstrip.should == "one\ntwo\nthree"
    end
  end

  context "with a string that has even LHS whitespace" do
    subject { PDF::Reader::JustifiedLeftStrip.new("  one\n  two\n  three")}

    it "should remove the whitespace" do
      subject.lstrip.should == "one\ntwo\nthree"
    end
  end

  context "with a string that has uneven LHS whitespace" do
    subject { PDF::Reader::JustifiedLeftStrip.new(" one\n  two\n  three")}

    it "should remove some of the whitespace" do
      subject.lstrip.should == "one\n two\n three"
    end
  end
end
