
module ParserHelper
  def parse_string (r)
    PDF::Reader::Parser.new(PDF::Reader::Buffer.new(sio = StringIO.new(r)), nil)
  end
end

context "The PDF::Reader::Parser class" do
  include ParserHelper

  specify "should parse a string correctly" do
    parse_string("this is a string)").string.should eql("this is a string")
    parse_string("this \\n is a string)").string.should eql("this \n is a string")
    parse_string("x \\t x)").string.should eql("x \t x")
    parse_string("x \\101 x)").string.should eql("x A x")
    parse_string("x \\( x)").string.should eql("x ( x")
    parse_string("(x)))").string.should eql("(x)")
    parse_string("Adobe)").string.should eql("Adobe")
    parse_string("!\"%1)").string.should eql("!\"%1")
    str = <<EOT
x
x \
x)
EOT
    parse_string(str).string.should eql("x\nx x")
  end

  specify "should parse a hex string correctly" do
    parse_string("48656C6C6F>").hex_string.should eql("Hello")
  end

  specify "should ignore whitespace when parsing a hex string" do
    parse_string("48656C6C6F20\n4A616D6573>").hex_string.should eql("Hello James")
  end

  specify "should parse various dictionaries correctly" do
    str = "/Registry (Adobe) /Ordering (Japan1) /Supplement 5 >>"
    dict = parse_string(str).dictionary

    dict.size.should eql(3)
    dict[:Registry].should    eql("Adobe")
    dict[:Ordering].should    eql("Japan1")
    dict[:Supplement].should  eql(5)
  end

  specify "should parse an array correctly" do
    parse_string("10 0 R 12 0 R ]").array.size.should eql(2)
  end
end
