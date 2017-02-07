# coding: utf-8

describe PDF::Reader::Parser do
  include ParserHelper
  include EncodingHelper

  it "parses a name correctly" do
    expect(parse_string("/James").parse_token).to eql(:James)
    expect(parse_string("/A;Name_With-Various***Characters?").parse_token).to eql(:"A;Name_With-Various***Characters?")
    expect(parse_string("/1.2").parse_token).to eql(:"1.2")
    expect(parse_string("/$$").parse_token).to eql(:"$$")
    expect(parse_string("/@pattern").parse_token).to eql(:"@pattern")
    expect(parse_string("/.notdef").parse_token).to eql(:".notdef")
    expect(parse_string("/James#20Healy").parse_token).to eql(:"James Healy")
    expect(parse_string("/James#23Healy").parse_token).to eql(:"James#Healy")
    expect(parse_string("/Ja#6des").parse_token).to eql(:"James")
    expect(parse_string("/Ja#6des").parse_token).to eql(:"James")
  end

  it "parses an empty name correctly" do
    expect(parse_string("/").parse_token).to eql("".to_sym)
    parser = parse_string("/\n/")
    expect(parser.parse_token).to eql("".to_sym)
    expect(parser.parse_token).to eql("".to_sym)
  end

  it "parses two empty names correctly" do
    parser = parse_string("/ /")
    expect(parser.parse_token).to eql("".to_sym)
    expect(parser.parse_token).to eql("".to_sym)
  end

  it "parses booleans correctly" do
    expect(parse_string("true").parse_token).to be_truthy
    expect(parse_string("false").parse_token).to be_falsey
  end

  it "parses null and nil correctly" do
    expect(parse_string("").parse_token).to be_nil
    expect(parse_string("null").parse_token).to be_nil
  end

  it "parses a string correctly" do
    expect(parse_string("()").parse_token).to eql("")
    expect(parse_string("(this is a string)").parse_token).to eql("this is a string")
    expect(parse_string("(this \\n is a string)").parse_token).to eql("this \n is a string")
    expect(parse_string("(x \\t x)").parse_token).to eql("x \t x")
    expect(parse_string("(x \\101 x)").parse_token).to eql("x A x")
    expect(parse_string("(x \\61 x)").parse_token).to eql("x 1 x")
    expect(parse_string("(x \\1 x)").parse_token).to eql("x \x01 x")
    expect(parse_string("(x \\( x)").parse_token).to eql("x ( x")
    expect(parse_string("((x)))").parse_token).to eql("(x)")
    expect(parse_string("(Adobe)").parse_token).to eql("Adobe")
    expect(parse_string("(!\"%1)").parse_token).to eql("!\"%1")
    expect(parse_string("(James\\ Healy)").parse_token).to eql("James Healy")
    expect(parse_string("(x\nx)").parse_token).to eql("x\nx")
    expect(parse_string("(x\rx)").parse_token).to eql("x\nx")
    expect(parse_string("(x\r\nx)").parse_token).to eql("x\nx")
    expect(parse_string("(x\\rx)").parse_token).to eql("x\rx")
    expect(parse_string("(\\rx)").parse_token).to eql("\rx")
    expect(parse_string("(\\r)").parse_token).to eql("\r")
    expect(parse_string("(x\n\rx)").parse_token).to eql("x\nx")
    expect(parse_string("(x \\\nx)").parse_token).to eql("x x")
    expect(parse_string("(\\\\f)").parse_token).to eql("\\f")
    expect(parse_string("([test])").parse_token).to eql("[test]")
  end

  it "parses a Unicode string correctly" do
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
      expect(parse_string(src).parse_token).to eql(exp)
    end

    mixed = [ seq[:straddle_seq_5c6e], seq[:char_5c08], seq[:char_5c0a], seq[:char_5c02], seq[:char_contain_0a] ]
    mixed_src = binary_string("(" + bom + mixed.map {|x| x[0]}.join + ")")
    mixed_exp = binary_string(bom + mixed.map {|x| x[1]}.join)
    expect(parse_string(mixed_src).parse_token).to eql(mixed_exp)
  end

  it "does not leave the closing literal string delimiter in the buffer after parsing a string" do
    parser = parse_string("(this is a string) /James")
    expect(parser.parse_token).to eql("this is a string")
    expect(parser.parse_token).to eql(:James)
  end

  it "parses a hex string correctly" do
    expect(parse_string("<48656C6C6F>").parse_token).to eql("Hello")
  end

  it "ignores whitespace when parsing a hex string" do
    expect(parse_string("<48656C6C6F20\n4A616D6573>").parse_token).to eql("Hello James")
  end

  context "with an unclosed hex string" do
    it "raises an exception" do
      expect {
        parse_string("<48656C6C6F").parse_token
      }.to raise_error(PDF::Reader::MalformedPDFError, "unterminated hex string")
    end
  end

  it "parses dictionary with embedded hex string correctly" do
    dict = parse_string("<< /X <48656C6C6F> >>").parse_token
    expect(dict.size).to eql(1)
    expect(dict[:X]).to eql("Hello")
  end

  it "parses various dictionaries correctly" do
    str = "<< /Registry (Adobe) /Ordering (Japan1) /Supplement 5 >>"
    dict = parse_string(str).parse_token

    expect(dict.size).to eql(3)
    expect(dict[:Registry]).to    eql("Adobe")
    expect(dict[:Ordering]).to    eql("Japan1")
    expect(dict[:Supplement]).to  eql(5)
  end

  it "parses dictionary with extra space ok" do
    str = "<<\r\n/Type /Pages\r\n/Count 3\r\n/Kids [ 25 0 R 27 0 R]\r\n                                                      \r\n>>"
    dict = parse_string(str).parse_token
    expect(dict.size).to eq(3)
  end

  context "with an unclosed dict" do
    it "raises an exception" do
      expect {
        parse_string("<< /Registry (Adobe) ").parse_token
      }.to raise_error(PDF::Reader::MalformedPDFError, "unterminated dict")
    end
  end

  it "parses an array correctly" do
    expect(parse_string("[ 10 0 R 12 0 R ]").parse_token.size).to eql(2)
  end

  context "with an unclosed array" do
    it "raises an exception" do
      expect {
        parse_string("[ 1 2 3").parse_token
      }.to raise_error(PDF::Reader::MalformedPDFError, "unterminated array")
    end
  end

  it "parses numbers correctly" do
    parser = parse_string("1 2 -3 4.5 -5")
    expect(parser.parse_token).to eql( 1)
    expect(parser.parse_token).to eql( 2)
    expect(parser.parse_token).to eql(-3)
    expect(parser.parse_token).to eql( 4.5)
    expect(parser.parse_token).to eql(-5)
  end

end
