# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Parser do
  include ParserHelper
  include EncodingHelper

  it "should parse a name correctly" do
    parse_string("/James").parse_token.should eql(:James)
    parse_string("/A;Name_With-Various***Characters?").parse_token.should eql(:"A;Name_With-Various***Characters?")
    parse_string("/1.2").parse_token.should eql(:"1.2")
    parse_string("/$$").parse_token.should eql(:"$$")
    parse_string("/@pattern").parse_token.should eql(:"@pattern")
    parse_string("/.notdef").parse_token.should eql(:".notdef")
    parse_string("/James#20Healy").parse_token.should eql(:"James Healy")
    parse_string("/James#23Healy").parse_token.should eql(:"James#Healy")
    parse_string("/Ja#6des").parse_token.should eql(:"James")
    parse_string("/Ja#6des").parse_token.should eql(:"James")
  end

  # '/' is a valid PDF name, but :"" is not a valid ruby symbol.
  # How should I handle this?
  it "should parse an empty name correctly" #do
    #parse_string("/").parse_token.should eql(:"")
  #end

  it "should parse booleans correctly" do
    parse_string("true").parse_token.should be_true
    parse_string("false").parse_token.should be_false
  end

  it "should parse null and nil correctly" do
    parse_string("").parse_token.should be_nil
    parse_string("null").parse_token.should be_nil
  end

  it "should parse a string correctly" do
    parse_string("()").parse_token.should eql("")
    parse_string("(this is a string)").parse_token.should eql("this is a string")
    parse_string("(this \\n is a string)").parse_token.should eql("this \n is a string")
    parse_string("(x \\t x)").parse_token.should eql("x \t x")
    parse_string("(x \\101 x)").parse_token.should eql("x A x")
    parse_string("(x \\61 x)").parse_token.should eql("x 1 x")
    parse_string("(x \\1 x)").parse_token.should eql("x \x01 x")
    parse_string("(x \\( x)").parse_token.should eql("x ( x")
    parse_string("((x)))").parse_token.should eql("(x)")
    parse_string("(Adobe)").parse_token.should eql("Adobe")
    parse_string("(!\"%1)").parse_token.should eql("!\"%1")
    parse_string("(James\\ Healy)").parse_token.should eql("James Healy")
    parse_string("(x\nx)").parse_token.should eql("x\nx")
    parse_string("(x\rx)").parse_token.should eql("x\nx")
    parse_string("(x\r\nx)").parse_token.should eql("x\nx")
    parse_string("(x\\rx)").parse_token.should eql("x\rx")
    parse_string("(\\rx)").parse_token.should eql("\rx")
    parse_string("(\\r)").parse_token.should eql("\r")
    parse_string("(x\n\rx)").parse_token.should eql("x\nx")
    parse_string("(x \\\nx)").parse_token.should eql("x x")
    parse_string("(\\\\f)").parse_token.should eql("\\f")
    parse_string("([test])").parse_token.should eql("[test]")
  end

  it "should parse a Unicode string correctly" do
    seq = {
      # key                 source                  expected               confusing to
      :straddle_seq_5c6e =>["\x4F\x5C\x5C\x6E\x05", "\x4F\x5C\x6E\x05"], # /.\n./
      :straddle_seq_5c72 =>["\x4F\x5C\x5C\x72\x06", "\x4F\x5C\x72\x06"], # /.\r./
      :straddle_seq_5c74 =>["\x4F\x5C\x5C\x74\x06", "\x4F\x5C\x74\x06"], # /.\t./
      :straddle_seq_5c62 =>["\x4F\x5C\x5C\x62\x10", "\x4F\x5C\x62\x10"], # /.\b./
      :straddle_seq_5c66 =>["\x4F\x5C\x5C\x66\xFF", "\x4F\x5C\x66\xFF"], # /.\f./
      :char_5c08         =>["\x5C\x5C\x08",         "\x5C\x08"],         # /\\\b/
      :char_5c09         =>["\x5C\x5C\x09",         "\x5C\x09"],         # /\\\t/
      :char_5c0a         =>["\x5C\x5C\x5C\x6E",     "\x5C\x0A"],         # /\\\n/
      :char_5c0d         =>["\x5C\x5C\x5C\x72",     "\x5C\x0D"],         # /\\\r/
      :char_5c28         =>["\x5C\x5C\x5C\x28",     "\x5C\x28"],         # /\\(/
      :char_5c6e         =>["\x5C\x5C\x6E",         "\x5C\x6E"],         # /\\n/
      :char_5c02         =>["\x5C\x5C\x02",         "\x5C\x02"],         # /\\./
      :char_5c71         =>["\x5C\x5C\x71",         "\x5C\x71"],         # /\\./
      :char_contain_08   =>["\x4E\x08",             "\x4E\x08"],         # /.\b/
      :char_contain_09   =>["\x4E\x09",             "\x4E\x09"],         # /.\t/
      :char_contain_0a   =>["\x4E\x5C\x6E",         "\x4E\x0A"],         # /.\n/
      :char_contain_0c   =>["\x54\x0C",             "\x54\x0C"],         # /.\f/
      :char_contain_0d   =>["\x69\x5C\x72",         "\x69\x0D"],         # /.\r/
      :char_contain_28   =>["\x75\x5C\x28",         "\x75\x28"],         # /.(/
      :char_contain_29   =>["\x52\x5C\x29",         "\x52\x29"],         # /.)/
    }
    bom = "\xFE\xFF"

    seq.each_value do |(src, exp)|
      src = binary_string("(#{bom}#{src})")
      exp = binary_string("#{bom}#{exp}")
      parse_string(src).parse_token.should eql(exp)
    end

    mixed = [ seq[:straddle_seq_5c6e], seq[:char_5c08], seq[:char_5c0a], seq[:char_5c02], seq[:char_contain_0a] ]
    mixed_src = binary_string("(" + bom + mixed.map {|x| x[0]}.join + ")")
    mixed_exp = binary_string(bom + mixed.map {|x| x[1]}.join)
    parse_string(mixed_src).parse_token.should eql(mixed_exp)
  end

  it "should not leave the closing literal string delimiter in the buffer after parsing a string" do
    parser = parse_string("(this is a string) /James")
    parser.parse_token.should eql("this is a string")
    parser.parse_token.should eql(:James)
  end

  it "should parse a hex string correctly" do
    parse_string("<48656C6C6F>").parse_token.should eql("Hello")
  end

  it "should ignore whitespace when parsing a hex string" do
    parse_string("<48656C6C6F20\n4A616D6573>").parse_token.should eql("Hello James")
  end

  it "should parse dictionary with embedded hex string correctly" do
    dict = parse_string("<< /X <48656C6C6F> >>").parse_token
    dict.size.should eql(1)
    dict[:X].should eql("Hello")
  end

  it "should parse various dictionaries correctly" do
    str = "<< /Registry (Adobe) /Ordering (Japan1) /Supplement 5 >>"
    dict = parse_string(str).parse_token

    dict.size.should eql(3)
    dict[:Registry].should    eql("Adobe")
    dict[:Ordering].should    eql("Japan1")
    dict[:Supplement].should  eql(5)
  end

  it "should parse an array correctly" do
    parse_string("[ 10 0 R 12 0 R ]").parse_token.size.should eql(2)
  end

  it "should parse numbers correctly" do
    parser = parse_string("1 2 -3 4.5 -5")
    parser.parse_token.should == 1
    parser.parse_token.should == 2
    parser.parse_token.should == -3
    parser.parse_token.should == 4.5
    parser.parse_token.should == -5
  end

end
