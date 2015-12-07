# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::ObjectHash do
  it "should have enumerable mixed in" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.map { |ref, obj| obj.class }.size).to eql(57)
  end
end

describe PDF::Reader::ObjectHash do
  it "should correctly load a PDF from a StringIO object" do
    filename = pdf_spec_file("cairo-unicode")
    io = StringIO.new(binread(filename))
    h = PDF::Reader::ObjectHash.new(io)

    expect(h.map { |ref, obj| obj.class }.size).to eql(57)
  end

  it "should raise an ArgumentError if passed a non filename and non IO" do
    filename = pdf_spec_file("cairo-unicode")
     expect {PDF::Reader::ObjectHash.new(10)}.to raise_error(ArgumentError)
  end

end

describe PDF::Reader::ObjectHash, "[] method" do

  it "should return nil for any invalid hash key" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h[-1]).to be_nil
    expect(h[nil]).to be_nil
    expect(h["James"]).to be_nil
  end

  it "should return nil for any hash key that doesn't exist" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h[10000]).to be_nil
  end

  it "should correctly extract an int object using int or string keys" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h[3]).to eql(3649)
    expect(h["3"]).to eql(3649)
    expect(h["3james"]).to eql(3649)
  end

  it "should correctly extract an int object using PDF::Reference as a key" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)
    ref = PDF::Reader::Reference.new(3,0)

    expect(h[ref]).to eql(3649)
  end
end

describe PDF::Reader::ObjectHash, "object method" do

  it "should return regular objects unchanged" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.object(-1)).to      eql(-1)
    expect(h.object(nil)).to     be_nil
    expect(h.object("James")).to eql("James")
  end

  it "should translate reference objects into an extracted PDF object" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.object(PDF::Reader::Reference.new(3,0))).to eql(3649)
  end
end

describe PDF::Reader::ObjectHash, "deref! method" do

  let(:hash) do
    PDF::Reader::ObjectHash.new pdf_spec_file("cairo-unicode")
  end

  it "should return regular objects unchanged" do
    expect(hash.deref!(-1)).to      eql(-1)
    expect(hash.deref!(nil)).to     be_nil
    expect(hash.deref!("James")).to eql("James")
  end

  it "should translate reference objects into an extracted PDF object" do
    expect(hash.deref!(PDF::Reader::Reference.new(3,0))).to eq 3649
  end

  it "should recursively dereference references within hashes" do
    font_descriptor = hash.deref! PDF::Reader::Reference.new(17, 0)
    expect(font_descriptor[:FontFile3]).to be_an_instance_of \
      PDF::Reader::Stream
  end

  it "should recursively dereference references within stream hashes" do
    font_file = hash.deref! PDF::Reader::Reference.new(15, 0)
    expect(font_file.hash[:Length]).to eq 2103
  end

  it "should recursively dereference references within arrays" do
    font = hash.deref! PDF::Reader::Reference.new(19, 0)
    expect(font[:DescendantFonts][0][:Subtype]).to eq :CIDFontType0
  end

  it "should return a new Hash, not mutate the provided Hash" do
    orig_collection = {}
    new_collection  = hash.deref!(orig_collection)

    expect(orig_collection.object_id).not_to eq(new_collection.object_id)
  end

  it "should return a new Array, not mutate the provided Array" do
    orig_collection = []
    new_collection  = hash.deref!(orig_collection)

    expect(orig_collection.object_id).not_to eq(new_collection.object_id)
  end

end

describe PDF::Reader::ObjectHash, "fetch method" do

  it "should raise IndexError for any invalid hash key when no default is provided" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect { h.fetch(-1) }.to raise_error(IndexError)
    expect { h.fetch(nil) }.to raise_error(IndexError)
    expect { h.fetch("James") }.to raise_error(IndexError)
  end

  it "should return default for any hash key that doesn't exist when a default is provided" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.fetch(10000, "default")).to eql("default")
  end

  it "should correctly extract an int object using int or string keys" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.fetch(3)).to eql(3649)
    expect(h.fetch("3")).to eql(3649)
    expect(h.fetch("3james")).to eql(3649)
  end

  it "should correctly extract an int object using PDF::Reader::Reference keys" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)
    ref = PDF::Reader::Reference.new(3,0)

    expect(h.fetch(ref)).to eql(3649)
  end
end

describe PDF::Reader::ObjectHash, "each method" do

  it "should iterate 57 times when using cairo-unicode PDF" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    count = 0
    h.each do
      count += 1
    end
    expect(count).to eql(57)
  end

  it "should provide a PDF::Reader::Reference to each iteration" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    h.each do |id, obj|
      expect(id).to be_a_kind_of(PDF::Reader::Reference)
      expect(obj).not_to be_nil
    end
  end
end

describe PDF::Reader::ObjectHash, "each_key method" do

  it "should iterate 57 times when using cairo-unicode PDF" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    count = 0
    h.each_key do
      count += 1
    end
    expect(count).to eql(57)
  end

  it "should provide a PDF::Reader::Reference to each iteration" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    h.each_key do |ref|
      expect(ref).to be_a_kind_of(PDF::Reader::Reference)
    end
  end
end

describe PDF::Reader::ObjectHash, "each_value method" do

  it "should iterate 57 times when using cairo-unicode PDF" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    count = 0
    h.each_value do
      count += 1
    end
    expect(count).to eql(57)
  end
end

describe PDF::Reader::ObjectHash, "size method" do

  it "should return 57 when using cairo-unicode PDF" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.size).to eql(57)
  end
end

describe PDF::Reader::ObjectHash, "empty? method" do

  it "should return false when using cairo-unicode PDF" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.empty?).to be_false
  end
end

describe PDF::Reader::ObjectHash, "has_key? method" do

  it "should return true when called with a valid ID" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.has_key?(1)).to be_true
    expect(h.has_key?(PDF::Reader::Reference.new(1,0))).to be_true
  end

  it "should return false when called with an invalid ID" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.has_key?(-1)).to be_false
    expect(h.has_key?(nil)).to be_false
    expect(h.has_key?("James")).to be_false
    expect(h.has_key?(PDF::Reader::Reference.new(10000,0))).to be_false
  end
end

describe PDF::Reader::ObjectHash, "has_value? method" do

  it "should return true when called with a valid object" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.has_value?(3649)).to be_true
  end

  it "should return false when called with an invalid object" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.has_value?(-1)).to be_false
    expect(h.has_value?(nil)).to be_false
    expect(h.has_value?("James")).to be_false
  end
end

describe PDF::Reader::ObjectHash, "keys method" do

  it "should return an array of keys" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    keys = h.keys
    expect(keys.size).to eql(57)
    keys.each { |k| expect(k).to be_a_kind_of(PDF::Reader::Reference) }
  end
end

describe PDF::Reader::ObjectHash, "values method" do

  it "should return an array of object" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    values = h.values
    expect(values.size).to eql(57)
    values.each { |v| expect(v).not_to be_nil }
  end
end

describe PDF::Reader::ObjectHash, "values_at method" do

  it "should return an array of object" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)
    ref3 = PDF::Reader::Reference.new(3,0)
    ref6 = PDF::Reader::Reference.new(6,0)

    expect(h.values_at(3,6)).to eql([3649,3287])
    expect(h.values_at(ref3,ref6)).to eql([3649,3287])
  end
end

describe PDF::Reader::ObjectHash, "to_a method" do

  it "should return an array of 57 arrays" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    arr = h.to_a
    expect(arr.size).to eql(57)
    arr.each { |a| expect(a).to be_a_kind_of(Array) }
  end
end

describe PDF::Reader::ObjectHash, "trailer method" do

  it "should return the document trailer dictionary" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expected = {:Size => 58,
                :Root => PDF::Reader::Reference.new(57,0),
                :Info => PDF::Reader::Reference.new(56,0)}
    expect(h.trailer[:Size]).to eql(58)
    expect(h.trailer[:Root]).to eql(PDF::Reader::Reference.new(57,0))
    expect(h.trailer[:Info]).to eql(PDF::Reader::Reference.new(56,0))
  end
end

describe PDF::Reader::ObjectHash, "pdf_version method" do

  it "should return the document PDF version dictionary" do
    filename = pdf_spec_file("cairo-unicode")
    h = PDF::Reader::ObjectHash.new(filename)

    expect(h.pdf_version).to eql(1.4)
  end
end

describe PDF::Reader::ObjectHash, "page_references method" do

  context "with cairo-unicode.pdf" do
    it "should return an ordered array of references to page objects" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      arr = h.page_references
      expect(arr.size).to eql(4)
      expect(arr.map { |ref| ref.id }).to eql([4, 7, 10, 13])
    end
  end

  context "with indirect_kids_array.pdf" do
    it "should return an ordered array of references to page objects" do
      filename = pdf_spec_file("indirect_kids_array")
      h = PDF::Reader::ObjectHash.new(filename)

      arr = h.page_references
      expect(arr.size).to eql(1)
      expect(arr.map { |ref| ref.id }).to eql([6])
    end
  end
end
