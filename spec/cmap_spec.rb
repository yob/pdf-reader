# typed: false
# coding: utf-8

describe PDF::Reader::CMap do

  describe "initialisation" do
    context "cmap with bfchar" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_bfchar.txt"
        map = PDF::Reader::CMap.new(binread(filename))
        expect(map.map).to be_a_kind_of(Hash)
        expect(map.size).to     eq(9)
        expect(map.map[0x1]).to eq([0x48])
        expect(map.map[0x2]).to eq([0x65])
        expect(map.map[0x9]).to eq([0x73])
      end
    end

    context "cmap with bfchar that converts a charatcer to a unicode codepoint" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_bfchar.txt"
        map = PDF::Reader::CMap.new(binread(filename))
        expect(map.decode(0x1)).to eq([0x48])
        expect(map.decode(0x2)).to eq([0x65])
        expect(map.decode(0x9)).to eq([0x73])
      end
    end

    context "cmap with bfchar and bfrange" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange.txt"
        map = PDF::Reader::CMap.new(binread(filename))
        expect(map.decode(0x16C9)).to eq([0x4F38]) # mapped with the bfchar operator
        expect(map.decode(0x0003)).to eq([0x0020]) # mapped with the bfrange operator
        expect(map.decode(0x0004)).to eq([0x0020+1]) # mapped with the bfrange operator
        expect(map.decode(0x0005)).to eq([0x0020+2]) # mapped with the bfrange operator
      end
    end

    context "cmap with bfrange and some indentation" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_two.txt"
        map = PDF::Reader::CMap.new(binread(filename))
        expect(map.decode(0x0100)).to eq([0x0100]) # mapped with the bfrange operator
        expect(map.decode(0xD900)).to eq([0xD900]) # mapped with the bfrange operator
      end
    end

    context "cmap with array version of bfrange" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_three.txt"
        map = PDF::Reader::CMap.new(binread(filename))

        expect(map.size).to eql(256)
        expect(map.decode(0x00)).to eq([0xfffd]) # mapped with the bfrange operator
        expect(map.decode(0x01)).to eq([0x0050]) # mapped with the bfrange operator
        expect(map.decode(0x03)).to eq([0x0067]) # mapped with the bfrange operator
        expect(map.decode(0x08)).to eq([0x0073]) # mapped with the bfrange operator
      end
    end

    context "when endbfrange is not on a dedicated line" do
      it "correctly loads a cmap" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_four.txt"
        map = PDF::Reader::CMap.new(binread(filename))

        expect(map.size).to eql(3)
        expect(map.decode(0x61)).to eq([0x61]) # mapped with the bfrange operator
        expect(map.decode(0x62)).to eq([0x62]) # mapped with the bfrange operator
        expect(map.decode(0x63)).to eq([0x63]) # mapped with the bfrange operator
      end
    end

    context "cmap with bfchar and ligatures" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_ligatures.txt"
        map = PDF::Reader::CMap.new(binread(filename))

        expect(map.decode(0x00B7)).to eql([0x2019])
        expect(map.decode(0x00C0)).to eql([0x66, 0x69])
        expect(map.decode(0x00C1)).to eql([0x66, 0x6C])
      end
    end

    context "cmap with bfchar and surrogate pairs" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_surrogate_pairs.txt"
        map = PDF::Reader::CMap.new(binread(filename))

        expect(map.decode(0x0502)).to eql([0x03D1])
        expect(map.decode(0x0C09)).to eql([0x1D6FD])
        expect(map.decode(0x0723)).to eql([0x1D434])
        expect(map.decode(0x0C23)).to eql([0x1D717])
        expect(map.decode(0x0526)).to eql([0x20D7])
        expect(map.decode(0x072B)).to eql([0x1D43C])
        expect(map.decode(0x122C)).to eql([0xFFFD])
      end
    end

    context "cmap with bfchar with surrogate pairs and ligatures" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_multiple_surrogate_pairs.txt"
        map = PDF::Reader::CMap.new(binread(filename))

        expect(map.decode(0x0BC9)).to eql([0x1D443, 0x1D443])
      end
    end

    context "cmap with bfrange containing > 255 characters" do
      it "correctly loads character mapping" do
        filename = File.dirname(__FILE__) + "/data/cmap_with_large_bfrange.txt"
        map = PDF::Reader::CMap.new(binread(filename))

        expect(map.decode(0x00B7)).to eql([0x00B7])
        expect(map.decode(0x00C0)).to eql([0x00C0])
        expect(map.decode(0x00C1)).to eql([0x00C1])
      end
    end
  end
end
