# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::CacheReport, "to_s method" do
  let!(:stats) do
    {
      PDF::Reader::Reference.new(1,0) => {:hits => 10, :misses => 3},
      PDF::Reader::Reference.new(2,0) => {:hits => 0, :misses => 10},
    }
  end

  let!(:report) { PDF::Reader::CacheReport.new(stats) }

  it "should return a string" do
    report.to_s.should be_a(String)
  end

  it "should return four lines" do
    report.to_s.split("\n").size.should == 4
  end

  it "should include a header line" do
    line = report.to_s.split("\n")[0]
    line.should == " reference  |     hits |   misses |    total "
  end

  it "should include a seperator line" do
    line = report.to_s.split("\n")[1]
    line.should == "*********************************************"
  end

  it "should report object 1 first" do
    line = report.to_s.split("\n")[2]
    line.should == " 1:0        |       10 |        3 |       13 "
  end

  it "should report object 2 second" do
    line = report.to_s.split("\n")[3]
    line.should == " 2:0        |        0 |       10 |       10 "
  end

end
