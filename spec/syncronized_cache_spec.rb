# typed: false
# coding: utf-8

require 'pdf/reader/synchronized_cache'

describe PDF::Reader::SynchronizedCache do
  describe "#[]=" do
    let(:cache) { PDF::Reader::SynchronizedCache.new }

    it "stores a value" do
      cache[:foo] = :bar
    end

  end

  describe "#[]" do
    let(:cache) { PDF::Reader::SynchronizedCache.new }

    it "returns a stored value" do
      cache[:foo] = :bar
      expect(cache[:foo]).to eq(:bar)
    end

  end
end
