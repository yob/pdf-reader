$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

class PDF::Reader::CMap
  attr_reader :map
end

context "PDF::Reader::CMap" do

  setup do
    
    @objstr = <<EOF
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo
<< /Registry (Adobe)
   /Ordering (UCS)
   /Supplement 0
>> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <ffff>
endcodespacerange
9 beginbfchar
<0001> <0048>
<0002> <0065>
<0003> <006c>
<0004> <006f>
<0005> <0020>
<0006> <004a>
<0007> <0061>
<0008> <006d>
<0009> <0073>
endbfchar
endcmap
CMapName currentdict /CMap defineresource pop
end
end
EOF
  end

  specify "should correctly load a cmap object string" do
    map = PDF::Reader::CMap.new(@objstr)
    map.map.should be_a_kind_of(Hash)
    map.map[0x1].should eql(0x48)
    map.map[0x2].should eql(0x65)
    map.map[0x9].should eql(0x73)
  end

  specify "should correctly convert a character code into a unicode codepoint" do
    map = PDF::Reader::CMap.new(@objstr)
    map.decode(0x1).should eql(0x48)
    map.decode(0x2).should eql(0x65)
    map.decode(0x9).should eql(0x73)
  end

end
