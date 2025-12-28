# typed: false
# coding: utf-8

describe PDF::Reader::Reference do
  describe "#hash" do

    it "returns the same hash for 2 identical objects" do
      one = PDF::Reader::Reference.new(1,0)
      two = PDF::Reader::Reference.new(1,0)

      expect(one.hash).to eq(two.hash)
    end

  end

  describe "#==" do

    it "returns true for the same object" do
      one = PDF::Reader::Reference.new(1,0)

      expect(one == one).to be_truthy
    end

    it "returns true for 2 identical objects" do
      one = PDF::Reader::Reference.new(1,0)
      two = PDF::Reader::Reference.new(1,0)

      expect(one == two).to be_truthy
    end

    it "returns false if one object isn't a Reference" do
      one = PDF::Reader::Reference.new(1,0)

      expect(one == "two").to be_falsey
    end

  end
end
