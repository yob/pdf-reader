# coding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context PDF::Hash do
  specify "should have enumerable mixed in" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.map { |ref, obj| obj.class }.size.should eql(57)
  end
end

context PDF::Hash do
  specify "should correctly load a PDF from a StringIO object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    io = StringIO.new(File.read(filename))
    h = PDF::Hash.new(io)

    h.map { |ref, obj| obj.class }.size.should eql(57)
  end

  specify "should raise an ArgumentError if passed a non filename and non IO" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
     lambda {PDF::Hash.new(10)}.should raise_error(ArgumentError)
  end
end

context PDF::Hash, "[] method" do

  specify "should return nil for any invalid hash key" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h[-1].should be_nil
    h[nil].should be_nil
    h["James"].should be_nil
  end

  specify "should return nil for any hash key that doesn't exist" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h[10000].should be_nil
  end

  specify "should correctly extract an int object using int or string keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h[3].should eql(3649)
    h["3"].should eql(3649)
    h["3james"].should eql(3649)
  end

  specify "should correctly extract an int object using PDF::Reference as a key" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)
    ref = PDF::Reader::Reference.new(3,0)

    h[ref].should eql(3649)
  end
end

context PDF::Hash, "fetch method" do

  specify "should raise IndexError for any invalid hash key when no default is provided" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    lambda { h.fetch(-1) }.should raise_error(IndexError)
    lambda { h.fetch(nil) }.should raise_error(IndexError)
    lambda { h.fetch("James") }.should raise_error(IndexError)
  end

  specify "should return default for any hash key that doesn't exist when a default is provided" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.fetch(10000, "default").should eql("default")
  end

  specify "should correctly extract an int object using int or string keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.fetch(3).should eql(3649)
    h.fetch("3").should eql(3649)
    h.fetch("3james").should eql(3649)
  end

  specify "should correctly extract an int object using PDF::Reader::Reference keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)
    ref = PDF::Reader::Reference.new(3,0)

    h.fetch(ref).should eql(3649)
  end
end

context PDF::Hash, "each method" do

  specify "should iterate 57 times when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    count = 0
    h.each do 
      count += 1
    end
    count.should eql(57)
  end

  specify "should provide a PDF::Reader::Reference to each iteration" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.each do |id, obj|
      id.should be_a_kind_of(PDF::Reader::Reference)
      obj.should_not be_nil
    end
  end
end

context PDF::Hash, "each_key method" do

  specify "should iterate 57 times when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    count = 0
    h.each_key do 
      count += 1
    end
    count.should eql(57)
  end

  specify "should provide a PDF::Reader::Reference to each iteration" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.each_key do |ref|
      ref.should be_a_kind_of(PDF::Reader::Reference)
    end
  end
end

context PDF::Hash, "each_value method" do

  specify "should iterate 57 times when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    count = 0
    h.each_value do 
      count += 1
    end
    count.should eql(57)
  end
end

context PDF::Hash, "size method" do

  specify "should return 57 when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.size.should eql(57)
  end
end

context PDF::Hash, "empty? method" do

  specify "should return false when using cairo-unicode PDF" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.empty?.should be_false
  end
end

context PDF::Hash, "has_key? method" do

  specify "should return true when called with a valid ID" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.has_key?(1).should be_true
    h.has_key?(PDF::Reader::Reference.new(1,0)).should be_true
  end

  specify "should return false when called with an invalid ID" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.has_key?(-1).should be_false
    h.has_key?(nil).should be_false
    h.has_key?("James").should be_false
    h.has_key?(PDF::Reader::Reference.new(10000,0)).should be_false
  end
end

context PDF::Hash, "has_value? method" do

  specify "should return true when called with a valid object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.has_value?(3649).should be_true
  end

  specify "should return false when called with an invalid object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.has_value?(-1).should be_false
    h.has_value?(nil).should be_false
    h.has_value?("James").should be_false
  end
end

context PDF::Hash, "keys method" do

  specify "should return an array of keys" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    keys = h.keys
    keys.size.should eql(57)
    keys.each { |k| k.should be_a_kind_of(PDF::Reader::Reference) }
  end
end

context PDF::Hash, "values method" do

  specify "should return an array of object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    values = h.values
    values.size.should eql(57)
    values.each { |v| v.should_not be_nil }
  end
end

context PDF::Hash, "values_at method" do

  specify "should return an array of object" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)
    ref3 = PDF::Reader::Reference.new(3,0)
    ref6 = PDF::Reader::Reference.new(6,0)

    h.values_at(3,6).should eql([3649,3287])
    h.values_at(ref3,ref6).should eql([3649,3287])
  end
end

context PDF::Hash, "to_a method" do

  specify "should return an array of 57 arrays" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    arr = h.to_a
    arr.size.should eql(57)
    arr.each { |a| a.should be_a_kind_of(Array) }
  end
end

context PDF::Hash, "trailer method" do

  specify "should return the document trailer dictionary" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    expected = {:Size => 58,
                :Root => PDF::Reader::Reference.new(57,0),
                :Info => PDF::Reader::Reference.new(56,0)}
    h.trailer[:Size].should eql(58)
    h.trailer[:Root].should eql(PDF::Reader::Reference.new(57,0))
    h.trailer[:Info].should eql(PDF::Reader::Reference.new(56,0))
  end
end

context PDF::Hash, "version method" do

  specify "should return the document PDF version dictionary" do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode.pdf"
    h = PDF::Hash.new(filename)

    h.version.should eql("1.4")
  end
end
