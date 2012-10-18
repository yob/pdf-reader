# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::CidWidths, "#initilize" do
  context "with an empty array" do
    subject { PDF::Reader::CidWidths.new(500, [])}

    it "should return the default width" do
      subject[1].should == 500
    end
  end

  context "with an array using the first form" do
    subject { PDF::Reader::CidWidths.new(500, [1, [10, 20, 30]])}

    it "should return correct width for index 1" do
      subject[1].should == 10
    end

    it "should return correct width for index 2" do
      subject[2].should == 20
    end

    it "should return correct width for index 3" do
      subject[3].should == 30
    end

    it "should return correct width for index 4" do
      subject[4].should == 500
    end
  end

  context "with an array using the second form" do
    subject { PDF::Reader::CidWidths.new(500, [1, 3, 10])}

    it "should return correct width for index 1" do
      subject[1].should == 10
    end

    it "should return correct width for index 2" do
      subject[2].should == 10
    end

    it "should return correct width for index 3" do
      subject[3].should == 10
    end

    it "should return correct width for index 4" do
      subject[4].should == 500
    end
  end

  context "with an array mixing the first and second form" do
    let!(:widths) {
      [
        1, [10, 20, 30],
        4, 6, 40,
      ]
    }
    subject       { PDF::Reader::CidWidths.new(500, widths)}

    it "should return correct width for index 1" do
      subject[1].should == 10
    end

    it "should return correct width for index 2" do
      subject[2].should == 20
    end

    it "should return correct width for index 3" do
      subject[3].should == 30
    end

    it "should return correct width for index 4" do
      subject[4].should == 40
    end

    it "should return correct width for index 5" do
      subject[5].should == 40
    end

    it "should return correct width for index 6" do
      subject[6].should == 40
    end

    it "should return correct width for index 7" do
      subject[7].should == 500
    end
  end

end
