# coding: utf-8

require "spec_helper"

describe PDF::Reader::OrientationDetector, "#orientation" do

  context "with a portrait page and no rotation" do
    let!(:detector) {
      PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 612, 792])
    }
    it "should return portrait" do
      detector.orientation.should == 'portrait'
    end
  end

  context "with a portrait page and -90° rotation" do
    let!(:detector) {
      PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 612, 792], :Rotate => 270)
    }
    it "should return landscape" do
      detector.orientation.should == 'landscape'
    end
  end

  context "with a landscape page and no rotation" do
    let!(:detector) {
      PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 792, 612])
    }
    it "should return landscape" do
      detector.orientation.should == 'landscape'
    end
  end

  context "with a landscape page and 90° rotation" do
    let!(:detector) {
      PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 792, 612], :Rotate => 90)
    }
    it "should return portrait" do
      detector.orientation.should == 'portrait'
    end
  end

end
