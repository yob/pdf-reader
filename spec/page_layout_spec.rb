# coding: utf-8

require "spec_helper"

describe PDF::Reader::PageLayout, "#to_s" do
  context "with an A4 page" do
    let(:mediabox) { [0, 0, 595.28, 841.89 ]}

    context "with no words" do
      subject { PDF::Reader::PageLayout.new([], mediabox)}

      it "should return a correct string" do
        subject.to_s.should == ""
      end
    end
    context "with one word" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello")
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello"
      end
    end
    context "with one run directly below another" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(30, 687, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello\nWorld"
      end
    end
    context "with one two words on one line, separated by a font size gap" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(92, 700, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello World"
      end
    end

    context "with two words on one line, separated just over the mean glyph width" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(91, 700, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello World"
      end
    end

    context "with one two words on one line, separated just over 2x the mean glyph width" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(101, 700, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello  World"
      end
    end

    context "with one run directly below another and indented by just over 1 font size gap" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(43, 687, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello\n World"
      end
    end

    context "with one run directly below another and the first indented by just over 1x fs gap" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(43, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(30, 687, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == " Hello\nWorld"
      end
    end

    context "with one run directly below another with 1 font size gap" do
      let!(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(30, 676, 50, 12, "World"),
        ]
      end
      subject { PDF::Reader::PageLayout.new(runs, mediabox)}

      it "should return a correct string" do
        subject.to_s.should == "Hello\n\nWorld"
      end
    end
  end
end
