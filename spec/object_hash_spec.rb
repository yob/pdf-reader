# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::ObjectHash do
  it "should have enumerable mixed in" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.map { |ref, obj| obj.class }.size.should eql(57)
  end
end

describe PDF::Reader::ObjectHash do
  it "should correctly load a PDF from a StringIO object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    io = StringIO.new(File.read(filename))
    h = PDF::Reader::ObjectHash.new(io)

    h.map { |ref, obj| obj.class }.size.should eql(57)
  end

  it "should raise an ArgumentError if passed a non filename and non IO" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
     lambda {PDF::Reader::ObjectHash.new(10)}.should raise_error(ArgumentError)
  end
end

describe PDF::Reader::ObjectHash, "[] method" do

  it "should return nil for any invalid hash key" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h[-1].should be_nil
    h[nil].should be_nil
    h["James"].should be_nil
  end

  it "should return nil for any hash key that doesn't exist" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h[10000].should be_nil
  end

  it "should correctly extract an int object using int or string keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h[3].should eql(3649)
    h["3"].should eql(3649)
    h["3james"].should eql(3649)
  end

  it "should correctly extract an int object using PDF::Reference as a key" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)
    ref = PDF::Reader::Reference.new(3,0)

    h[ref].should eql(3649)
  end
end

describe PDF::Reader::ObjectHash, "object method" do

  it "should return regular objects unchanged" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.object(-1).should      eql(-1)
    h.object(nil).should     be_nil
    h.object("James").should eql("James")
  end

  it "should translate reference objects into an extracted PDF object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.object(PDF::Reader::Reference.new(3,0)).should eql(3649)
  end
end

describe PDF::Reader::ObjectHash, "fetch method" do

  it "should raise IndexError for any invalid hash key when no default is provided" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    lambda { h.fetch(-1) }.should raise_error(IndexError)
    lambda { h.fetch(nil) }.should raise_error(IndexError)
    lambda { h.fetch("James") }.should raise_error(IndexError)
  end

  it "should return default for any hash key that doesn't exist when a default is provided" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.fetch(10000, "default").should eql("default")
  end

  it "should correctly extract an int object using int or string keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.fetch(3).should eql(3649)
    h.fetch("3").should eql(3649)
    h.fetch("3james").should eql(3649)
  end

  it "should correctly extract an int object using PDF::Reader::Reference keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)
    ref = PDF::Reader::Reference.new(3,0)

    h.fetch(ref).should eql(3649)
  end
end

describe PDF::Reader::ObjectHash, "each method" do

  it "should iterate 57 times when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    count = 0
    h.each do 
      count += 1
    end
    count.should eql(57)
  end

  it "should provide a PDF::Reader::Reference to each iteration" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.each do |id, obj|
      id.should be_a_kind_of(PDF::Reader::Reference)
      obj.should_not be_nil
    end
  end
end

describe PDF::Reader::ObjectHash, "each_key method" do

  it "should iterate 57 times when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    count = 0
    h.each_key do 
      count += 1
    end
    count.should eql(57)
  end

  it "should provide a PDF::Reader::Reference to each iteration" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.each_key do |ref|
      ref.should be_a_kind_of(PDF::Reader::Reference)
    end
  end
end

describe PDF::Reader::ObjectHash, "each_value method" do

  it "should iterate 57 times when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    count = 0
    h.each_value do 
      count += 1
    end
    count.should eql(57)
  end
end

describe PDF::Reader::ObjectHash, "size method" do

  it "should return 57 when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.size.should eql(57)
  end
end

describe PDF::Reader::ObjectHash, "empty? method" do

  it "should return false when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.empty?.should be_false
  end
end

describe PDF::Reader::ObjectHash, "has_key? method" do

  it "should return true when called with a valid ID" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.has_key?(1).should be_true
    h.has_key?(PDF::Reader::Reference.new(1,0)).should be_true
  end

  it "should return false when called with an invalid ID" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.has_key?(-1).should be_false
    h.has_key?(nil).should be_false
    h.has_key?("James").should be_false
    h.has_key?(PDF::Reader::Reference.new(10000,0)).should be_false
  end
end

describe PDF::Reader::ObjectHash, "has_value? method" do

  it "should return true when called with a valid object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.has_value?(3649).should be_true
  end

  it "should return false when called with an invalid object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.has_value?(-1).should be_false
    h.has_value?(nil).should be_false
    h.has_value?("James").should be_false
  end
end

describe PDF::Reader::ObjectHash, "keys method" do

  it "should return an array of keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    keys = h.keys
    keys.size.should eql(57)
    keys.each { |k| k.should be_a_kind_of(PDF::Reader::Reference) }
  end
end

describe PDF::Reader::ObjectHash, "values method" do

  it "should return an array of object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    values = h.values
    values.size.should eql(57)
    values.each { |v| v.should_not be_nil }
  end
end

describe PDF::Reader::ObjectHash, "values_at method" do

  it "should return an array of object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)
    ref3 = PDF::Reader::Reference.new(3,0)
    ref6 = PDF::Reader::Reference.new(6,0)

    h.values_at(3,6).should eql([3649,3287])
    h.values_at(ref3,ref6).should eql([3649,3287])
  end
end

describe PDF::Reader::ObjectHash, "to_a method" do

  it "should return an array of 57 arrays" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    arr = h.to_a
    arr.size.should eql(57)
    arr.each { |a| a.should be_a_kind_of(Array) }
  end
end

describe PDF::Reader::ObjectHash, "trailer method" do

  it "should return the document trailer dictionary" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    expected = {:Size => 58,
                :Root => PDF::Reader::Reference.new(57,0),
                :Info => PDF::Reader::Reference.new(56,0)}
    h.trailer[:Size].should eql(58)
    h.trailer[:Root].should eql(PDF::Reader::Reference.new(57,0))
    h.trailer[:Info].should eql(PDF::Reader::Reference.new(56,0))
  end
end

describe PDF::Reader::ObjectHash, "pdf_version method" do

  it "should return the document PDF version dictionary" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    h.pdf_version.should eql(1.4)
  end
end

describe PDF::Reader::ObjectHash, "page_references method" do

  it "should return the document PDF version dictionary" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Reader::ObjectHash.new(filename)

    arr = h.page_references
    arr.size.should eql(4)
    arr.map { |ref| ref.id }.should eql([4, 7, 10, 13])
  end
end
