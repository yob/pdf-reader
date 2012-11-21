# coding: utf-8

require "spec_helper"

describe PDF::Reader::PageLayout, "#to_s" do
  context "with two runs with different Y values" do
    let!(:runs) do
      [
        PDF::Reader::TextRun.new(30, 700, 50, "Hello"),
        PDF::Reader::TextRun.new(30, 693, 50, "World"),
      ]
    end
    subject { PDF::Reader::PageLayout.new(runs)}

    it "should return a correct string" do
      subject.to_s.should == "Hello\nWorld"
    end
  end

  context "with two runs with the same Y values and 10pts between X locations" do
    let!(:runs) do
      [
        PDF::Reader::TextRun.new(30, 700, 50, "Hello"),
        PDF::Reader::TextRun.new(90, 700, 50, "World"),
      ]
    end
    subject { PDF::Reader::PageLayout.new(runs)}

    it "should return a correct string" do
      subject.to_s.should == "HelloWorld"
    end
  end

  context "with two runs with the same Y values and 20pts between X locations" do
    let!(:runs) do
      [
        PDF::Reader::TextRun.new(30, 700, 50, "Hello"),
        PDF::Reader::TextRun.new(100, 700, 50, "World"),
      ]
    end
    subject { PDF::Reader::PageLayout.new(runs)}

    it "should return a correct string" do
      subject.to_s.should match(/Hello\s+World/)
    end
  end

end
