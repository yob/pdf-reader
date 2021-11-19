# typed: false
# coding: utf-8

describe PDF::Reader::ObjectHash do
  describe "mixins" do
    it "has enumerable mixed in" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.map { |ref, obj| obj.class }.size).to eql(57)
    end
  end

  describe "initialisation" do
    it "correctly loads a PDF from a StringIO object" do
      filename = pdf_spec_file("cairo-unicode")
      io = StringIO.new(binread(filename))
      h = PDF::Reader::ObjectHash.new(io)

      expect(h.map { |ref, obj| obj.class }.size).to eql(57)
    end

    it "raises an ArgumentError if passed a non filename and non IO" do
      pdf_spec_file("cairo-unicode")
      expect {PDF::Reader::ObjectHash.new(10)}.to raise_error(ArgumentError)
    end
  end

  describe "#[]" do

    it "returns nil for any invalid hash key" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h[-1]).to be_nil
      expect(h[nil]).to be_nil
      expect(h["James"]).to be_nil
    end

    it "returns nil for any hash key that doesn't exist" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h[10000]).to be_nil
    end

    it "correctly extracts an int object using int or string keys" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h[3]).to eql(3649)
      expect(h["3"]).to eql(3649)
      expect(h["3james"]).to eql(3649)
    end

    it "correctly extracts an int object using PDF::Reference as a key" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)
      ref = PDF::Reader::Reference.new(3,0)

      expect(h[ref]).to eql(3649)
    end
  end

  describe "#object" do

    it "returns regular objects unchanged" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.object(-1)).to      eql(-1)
      expect(h.object(nil)).to     be_nil
      expect(h.object("James")).to eql("James")
    end

    it "translates reference objects into an extracted PDF object" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.object(PDF::Reader::Reference.new(3,0))).to eql(3649)
    end
  end

  describe "#deref!" do

    let(:hash) do
      PDF::Reader::ObjectHash.new pdf_spec_file("cairo-unicode")
    end

    it "returns regular objects unchanged" do
      expect(hash.deref!(-1)).to      eql(-1)
      expect(hash.deref!(nil)).to     be_nil
      expect(hash.deref!("James")).to eql("James")
    end

    it "translates reference objects into an extracted PDF object" do
      expect(hash.deref!(PDF::Reader::Reference.new(3,0))).to eq 3649
    end

    it "recursively dereferences references within hashes" do
      font_descriptor = hash.deref! PDF::Reader::Reference.new(17, 0)
      expect(font_descriptor[:FontFile3]).to be_an_instance_of \
        PDF::Reader::Stream
    end

    it "recursively dereferences references within stream hashes" do
      font_file = hash.deref! PDF::Reader::Reference.new(15, 0)
      expect(font_file.hash[:Length]).to eq 2103
    end

    it "recursively dereferences references within arrays" do
      font = hash.deref! PDF::Reader::Reference.new(19, 0)
      expect(font[:DescendantFonts][0][:Subtype]).to eq :CIDFontType0
    end

    it "returns a new Hash, not mutate the provided Hash" do
      orig_collection = {}
      new_collection  = hash.deref!(orig_collection)

      expect(orig_collection.object_id).not_to eq(new_collection.object_id)
    end

    it "returns a new Array, not mutate the provided Array" do
      orig_collection = []
      new_collection  = hash.deref!(orig_collection)

      expect(orig_collection.object_id).not_to eq(new_collection.object_id)
    end

    # a -> b -> c -> a
    context "with nested Array's that reference themselves" do
      let(:a) { [1, b] }
      let(:b) { [2, c] }
      let(:c) { [3] }

      before do
        c << a
      end

      it "returns a new Array, not mutate the provided Array" do
        result = hash.deref!(c)

        expect(result).to be_a(Array)
      end
    end
  end

  describe "#fetch" do

    it "raises IndexError for any invalid hash key when no default is provided" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect { h.fetch(-1) }.to raise_error(IndexError)
      expect { h.fetch(nil) }.to raise_error(IndexError)
      expect { h.fetch("James") }.to raise_error(IndexError)
    end

    it "returns default for any hash key that doesn't exist when a default is provided" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.fetch(10000, "default")).to eql("default")
    end

    it "correctly extracts an int object using int or string keys" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.fetch(3)).to eql(3649)
      expect(h.fetch("3")).to eql(3649)
      expect(h.fetch("3james")).to eql(3649)
    end

    it "correctly extracts an int object using PDF::Reader::Reference keys" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)
      ref = PDF::Reader::Reference.new(3,0)

      expect(h.fetch(ref)).to eql(3649)
    end
  end

  describe "#each" do

    it "iterates 57 times when using cairo-unicode PDF" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      count = 0
      h.each do
        count += 1
      end
      expect(count).to eql(57)
    end

    it "provides a PDF::Reader::Reference to each iteration" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      h.each do |id, obj|
        expect(id).to be_a_kind_of(PDF::Reader::Reference)
        expect(obj).not_to be_nil
      end
    end
  end

  describe "#each_key" do

    it "iterates 57 times when using cairo-unicode PDF" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      count = 0
      h.each_key do
        count += 1
      end
      expect(count).to eql(57)
    end

    it "provides a PDF::Reader::Reference to each iteration" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      h.each_key do |ref|
        expect(ref).to be_a_kind_of(PDF::Reader::Reference)
      end
    end
  end

  describe "#each_value" do

    it "iterates 57 times when using cairo-unicode PDF" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      count = 0
      h.each_value do
        count += 1
      end
      expect(count).to eql(57)
    end
  end

  describe "#size" do

    it "returns 57 when using cairo-unicode PDF" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.size).to eql(57)
    end
  end

  describe "#empty?" do

    it "returns false when using cairo-unicode PDF" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.empty?).to be_falsey
    end
  end

  describe "#has_key?" do

    it "returns true when called with a valid ID" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.has_key?(1)).to be_truthy
      expect(h.has_key?(PDF::Reader::Reference.new(1,0))).to be_truthy
    end

    it "returns false when called with an invalid ID" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.has_key?(-1)).to be_falsey
      expect(h.has_key?(nil)).to be_falsey
      expect(h.has_key?("James")).to be_falsey
      expect(h.has_key?(PDF::Reader::Reference.new(10000,0))).to be_falsey
    end
  end

  describe "#has_value?" do

    it "returns true when called with a valid object" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.has_value?(3649)).to be_truthy
    end

    it "returns false when called with an invalid object" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.has_value?(-1)).to be_falsey
      expect(h.has_value?(nil)).to be_falsey
      expect(h.has_value?("James")).to be_falsey
    end
  end

  describe "#keys" do

    it "returns an array of keys" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      keys = h.keys
      expect(keys.size).to eql(57)
      keys.each { |k| expect(k).to be_a_kind_of(PDF::Reader::Reference) }
    end
  end

  describe "#values" do

    it "returns an array of object" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      values = h.values
      expect(values.size).to eql(57)
      values.each { |v| expect(v).not_to be_nil }
    end
  end

  describe "#values_at" do

    it "returns an array of object" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)
      ref3 = PDF::Reader::Reference.new(3,0)
      ref6 = PDF::Reader::Reference.new(6,0)

      expect(h.values_at(3,6)).to eql([3649,3287])
      expect(h.values_at(ref3,ref6)).to eql([3649,3287])
    end
  end

  describe "#to_a" do

    it "returns an array of 57 arrays" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      arr = h.to_a
      expect(arr.size).to eql(57)
      arr.each { |a| expect(a).to be_a_kind_of(Array) }
    end
  end

  describe "#trailer" do

    it "returns the document trailer dictionary" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.trailer[:Size]).to eql(58)
      expect(h.trailer[:Root]).to eql(PDF::Reader::Reference.new(57,0))
      expect(h.trailer[:Info]).to eql(PDF::Reader::Reference.new(56,0))
    end
  end

  describe "#pdf_version" do

    it "returns the document PDF version dictionary" do
      filename = pdf_spec_file("cairo-unicode")
      h = PDF::Reader::ObjectHash.new(filename)

      expect(h.pdf_version).to eql(1.4)
    end
  end

  describe "#page_references" do

    context "with cairo-unicode.pdf" do
      it "returns an ordered array of references to page objects" do
        filename = pdf_spec_file("cairo-unicode")
        h = PDF::Reader::ObjectHash.new(filename)

        arr = h.page_references
        expect(arr.size).to eql(4)
        expect(arr.map { |ref| ref.id }).to eql([4, 7, 10, 13])
      end
    end

    context "with indirect_kids_array.pdf" do
      it "returns an ordered array of references to page objects" do
        filename = pdf_spec_file("indirect_kids_array")
        h = PDF::Reader::ObjectHash.new(filename)

        arr = h.page_references
        expect(arr.size).to eql(1)
        expect(arr.map { |ref| ref.id }).to eql([6])
      end
    end

    it "raises a MalformedPDFError if dereferenced value is not a dict" do
      filename = pdf_spec_file("page_reference_is_not_a_dict")
      h = PDF::Reader::ObjectHash.new(filename)
      expect { h.page_references }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end
end
