# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

context PDF::Reader::Page, "content_streams method" do

  it "should return an array of Stream objects for page 1 of cairo-basic.pdf" do
    @filename = File.dirname(__FILE__) + "/data/cairo-basic.pdf"
    @ohash    = PDF::Reader::ObjectHash.new(@filename)
    @dict     = @ohash[4]
    @page     = PDF::Reader::Page.new(@ohash, @dict)

    @page.content_streams.should      be_a(Array)
    @page.content_streams.size.should eql(1)
    @page.content_streams.each do |obj|
      obj.should be_a(PDF::Reader::Stream)
    end
  end

  it "should return an array of Stream objects for page 1 of split_params_and_operator.pdf" do
    @filename = File.dirname(__FILE__) + "/data/split_params_and_operator.pdf"
    @ohash    = PDF::Reader::ObjectHash.new(@filename)
    @dict     = @ohash[5]
    @page     = PDF::Reader::Page.new(@ohash, @dict)

    @page.content_streams.should      be_a(Array)
    @page.content_streams.size.should eql(2)
    @page.content_streams.each do |obj|
      obj.should be_a(PDF::Reader::Stream)
    end
  end
end

context PDF::Reader::Page, "parents method" do

  it "should return an array of PDF Page objects for page 1 of cairo-basic.pdf" do
    @filename = File.dirname(__FILE__) + "/data/cairo-basic.pdf"
    @ohash    = PDF::Reader::ObjectHash.new(@filename)
    @dict     = @ohash[4]
    @page     = PDF::Reader::Page.new(@ohash, @dict)

    @page.parents.should      be_a(Array)
    @page.parents.size.should eql(1)
    @page.parents.each do |obj|
      obj.should be_a(Hash)
      obj[:Type].should eql(:Pages)
    end
  end
end

context PDF::Reader::Page, "resources method" do

  it "should return a hash of Resources applicable to page 1 of cairo-basic.pdf" do
    @filename = File.dirname(__FILE__) + "/data/cairo-basic.pdf"
    @ohash    = PDF::Reader::ObjectHash.new(@filename)
    @dict     = @ohash[4]
    @page     = PDF::Reader::Page.new(@ohash, @dict)

    @page.resources.should       be_a(Hash)
    @page.resources.size.should eql(2)
    @page.resources.keys.include?(:Font).should be_true
    @page.resources.keys.include?(:ExtGState).should be_true
  end

  it "should return a hash of Resources applicable to page 1 of split_params_and_operator.pdf" do
    @filename = File.dirname(__FILE__) + "/data/split_params_and_operator.pdf"
    @ohash    = PDF::Reader::ObjectHash.new(@filename)
    @dict     = @ohash[5]
    @page     = PDF::Reader::Page.new(@ohash, @dict)

    @page.resources.should       be_a(Hash)
    @page.resources.size.should eql(2)
    @page.resources.keys.include?(:Font).should be_true
    @page.resources.keys.include?(:ProcSet).should be_true
  end
end

context PDF::Reader::Page, "fonts method" do

  it "should return a hash of Fonts applicable to page 1 of cairo-basic.pdf" do
    @filename = File.dirname(__FILE__) + "/data/cairo-basic.pdf"
    @ohash    = PDF::Reader::ObjectHash.new(@filename)
    @dict     = @ohash[4]
    @page     = PDF::Reader::Page.new(@ohash, @dict)

    @page.fonts.should       be_a(Hash)
    @page.fonts.size.should eql(1)
    @page.fonts.keys[0].should eql(:"CairoFont-0-0")
    @page.fonts.values[0].should be_a(PDF::Reader::Font)
  end
end
