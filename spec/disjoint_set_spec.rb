# typed: false
# coding: utf-8

describe PDF::Reader::DisjointSet do
  let(:set) { PDF::Reader::DisjointSet.new }

  describe "#add" do
    it "adds a new item to the set" do
      set.add(5)
      expect(set.length).to eq(1)
      expect(set.contains(5)).to be_truthy
    end
  end

  describe "#each" do
    let(:set) do
      set = PDF::Reader::DisjointSet.new
      set.add(1)
      set.add(2)
      set.add(3)
      set.union(1, 2)
    end

    it "iterates over each item in the set (even if unions are created)" do
      expect(set.each.to_a).to eq([1, 2, 3])
    end

    it "is used by Enumerable to provide iterative functionality like #map" do
      result = set.map { |x| x.to_s }
      expect(result).to eq(['1', '2', '3'])
    end
  end

  describe "#find" do
    it "finds the parent of the item" do
      set.add("parent")
      set.add("child")
      set.union("parent", "child")
      expect(set.find("parent")).to eq("parent")
      expect(set.find("child")).to eq("parent")
    end

    it "returns the item if it is a parent" do
      set.add("item")
      expect(set.find("item")).to eq("item")
    end
  end

  describe "#sets" do
    it "returns an array of arrays containing the sets" do
      set.add("parent")
      set.add("child")
      set.add("unrelated")
      set.union("parent", "child")
      expect(set.sets).to eq([["parent", "child"], ["unrelated"]])
    end
  end

  describe "#union" do
    let(:set) do
      set = PDF::Reader::DisjointSet.new
      set.add("parent")
      set.add("child")
      set.add("grandchild")
      set.add("unrelated")
    end

    it "handles multiple unions" do
      set.union("parent", "child")
      set.union("child", "grandchild")
      expect(set.sets).to eq([["parent", "child", "grandchild"], ["unrelated"]])
    end

    it "handles union params regardless of order" do
      set.union("child", "parent")
      set.union("grandchild", "child")
      expect(set.sets).to eq([["parent", "child", "grandchild"], ["unrelated"]])
    end

    it "gracefully handles union of identical elements" do
      set.union("child", "child")
      expect(set.sets).to eq([["parent"], ["child"], ["grandchild"], ["unrelated"]])
    end

    it "handles joining multiple previous unions" do
      set = PDF::Reader::DisjointSet.new
      set.add("parent1")
      set.add("child1")
      set.add("parent2")
      set.add("child2")
      set.union("parent1", "child1")
      set.union("parent2", "child2")
      set.union("parent1", "parent2")
      expect(set.sets).to eq([["parent1", "child1", "parent2", "child2"]])
    end
  end
end
