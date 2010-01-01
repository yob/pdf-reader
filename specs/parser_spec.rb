require File.dirname(__FILE__) + "/spec_helper"

context "The PDF::Reader::Parser class" do
  include ParserHelper

  specify "should parse a name correctly" do
    parse_string("/James").parse_token.should eql(:James)
  end

  specify "should parse booleans correctly" do
    parse_string("true").parse_token.should be_true
    parse_string("false").parse_token.should be_false
  end

  specify "should parse null and nil correctly" do
    parse_string("").parse_token.should be_nil
    parse_string("null").parse_token.should be_nil
  end

  specify "should parse a string correctly" do
    parse_string("()").parse_token.should eql("")
    parse_string("(this is a string)").parse_token.should eql("this is a string")
    parse_string("(this \\n is a string)").parse_token.should eql("this \n is a string")
    parse_string("(x \\t x)").parse_token.should eql("x \t x")
    parse_string("(x \\101 x)").parse_token.should eql("x A x")
    parse_string("(x \\( x)").parse_token.should eql("x ( x")
    parse_string("((x)))").parse_token.should eql("(x)")
    parse_string("(Adobe)").parse_token.should eql("Adobe")
    parse_string("(!\"%1)").parse_token.should eql("!\"%1")
    parse_string("(James\\ Healy)").parse_token.should eql("James Healy")
    parse_string("(x\nx)").parse_token.should eql("x\nx")
    parse_string("(x\rx)").parse_token.should eql("x\nx")
    parse_string("(x\r\nx)").parse_token.should eql("x\nx")
    parse_string("(x\n\rx)").parse_token.should eql("x\nx")
    parse_string("(x \x5C\nx)").parse_token.should eql("x x")
  end

  specify "should not leave the closing literal string delimiter in the buffer after parsing a string" do
    parser = parse_string("(this is a string) /James")
    parser.parse_token.should eql("this is a string")
    parser.parse_token.should eql(:James)
  end

  specify "should parse a hex string correctly" do
    parse_string("<48656C6C6F>").parse_token.should eql("Hello")
  end

  specify "should ignore whitespace when parsing a hex string" do
    parse_string("<48656C6C6F20\n4A616D6573>").parse_token.should eql("Hello James")
  end

  specify "should parse various dictionaries correctly" do
    str = "<< /Registry (Adobe) /Ordering (Japan1) /Supplement 5 >>"
    dict = parse_string(str).parse_token

    dict.size.should eql(3)
    dict[:Registry].should    eql("Adobe")
    dict[:Ordering].should    eql("Japan1")
    dict[:Supplement].should  eql(5)
  end

  specify "should parse an array correctly" do
    parse_string("[ 10 0 R 12 0 R ]").parse_token.size.should eql(2)
  end

end
