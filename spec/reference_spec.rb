# coding: utf-8

describe Marron::Reference do
  describe "#hash" do

    it "returns the same hash for 2 identical objects" do
      one = Marron::Reference.new(1,0)
      two = Marron::Reference.new(1,0)

      expect(one.hash).to eq(two.hash)
    end

  end

  describe "#==" do

    it "returns true for the same object" do
      one = Marron::Reference.new(1,0)

      expect(one == one).to be_truthy
    end

    it "returns true for 2 identical objects" do
      one = Marron::Reference.new(1,0)
      two = Marron::Reference.new(1,0)

      expect(one == two).to be_truthy
    end

    it "returns false if one object isn't a Reference" do
      one = Marron::Reference.new(1,0)

      expect(one == "two").to be_falsey
    end

  end
end
