# coding: utf-8

require 'spec_helper'

describe PDF::Reader::NewParser do
  include EncodingHelper

  it "should parse a literal string" do
    str    = "(abc)"
    tokens = %w{ abc }
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse two literal strings" do
    str    = "(abc) (def)"
    tokens = %w{ abc def }
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string with capitals" do
    str    = "(ABC)"
    tokens = %w{ ABC }
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string with spaces" do
    str    = " (abc) "
    tokens = %w{ abc }
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an empty literal string" do
    str    = "()"
    tokens = [""]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing spaces" do
    str    = "(this is a string)"
    tokens = ["this is a string"]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing an escaped new line" do
    str    = '(this \n is a string)'
    tokens = ['this \n is a string']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing an escaped tab" do
    str    = '(x \t x)'
    tokens = ['x \t x']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing an escaped octal" do
    str    = '(x \101 x)'
    tokens = ['x \101 x']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing an escaped digit" do
    str    = '(x \1 x)'
    tokens = ['x \1 x']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing an escaped left paren" do
    str    = '(x \( x)'
    tokens = ['x \( x']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing an escaped right paren" do
    str    = '(x \) x)'
    tokens = ['x \) x']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a literal string containing balanced parens" do
    str    = '((x))'
    tokens = ['(x)']
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a hex string without captials" do
    str    = "<00ffab>"
    tokens = [ binary_string("\x00\xff\xab") ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a hex string with captials" do
    str    = " <00FFAB> "
    tokens = [ binary_string("\x00\xFF\xAB") ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse two hex strings" do
    str    = " <00FF> <2030>"
    tokens = [ binary_string("\x00\xFF"), binary_string("\x20\x30") ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a hex string with white space" do
    str    = "<00FF\n2030>"
    tokens = [ binary_string("\x00\xFF\x20\x30") ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an integer" do
    str    = "9"
    tokens = [ 9 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse two integers" do
    str    = "9 9"
    tokens = [ 9, 9 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a double digit integer" do
    str    = "99"
    tokens = [ 99 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a triple digit integer" do
    str    = "123"
    tokens = [123 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an integer with spaces" do
    str    = " 19 "
    tokens = [ 19 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an integer with a plus sign" do
    str    = "+15"
    tokens = [ 15 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an integer with a minus sign" do
    str    = "-34"
    tokens = [ -34 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a float" do
    str    = "1.1"
    tokens = [ 1.1 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a float with a plus sign" do
    str    = "+19.1"
    tokens = [ 19.1 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a float with a minus sign" do
    str    = "-73.2"
    tokens = [ -73.2 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a float with spaces" do
    str    = " 19.9 "
    tokens = [ 19.9 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name" do
    str    = "/James"
    tokens = [ :James ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with spaces" do
    str    = " /James "
    tokens = [ :James ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with odd but legal characters" do
    str    = "/A;Name_With-Various***Characters?"
    tokens = [ :"A;Name_With-Various***Characters?" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name that looks like a float" do
    str    = " /1.2 "
    tokens = [ :"1.2" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with a dollar sign" do
    str    = " /$$ "
    tokens = [ :"$$" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with an @ sign" do
    str    = "/@pattern"
    tokens = [ :"@pattern" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with a decimal point" do
    str    = "/.notdef"
    tokens = [ :".notdef" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with an encoded space" do
    str    = "/James#20Healy"
    tokens = [ :"James Healy" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with an encoded #" do
    str    = "/James#23Healy"
    tokens = [ :"James#Healy" ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a pdf name with an encoded m" do
    str    = "/Ja#6des"
    tokens = [ :James ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a true boolean" do
    str    = "true"
    tokens = [ true ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a false boolean" do
    str    = "false"
    tokens = [ false ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a null" do
    str    = "null"
    tokens = [ nil ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an array of ints" do
    str    = "[ 1 2 3 0 0 4 ]"
    tokens = [[ 1, 2, 3, 0, 0, 4 ]]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an array of indirect objects" do
    str    = "[ 10 0 R 12 0 R ]"
    tokens = [[ "10 0 R", "12 0 R" ]]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a simple dictionary" do
    str    = "<</One 1 /Two 2>>"
    tokens = [ {:One => 1, :Two => 2} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a dictionary with an embedded hex string" do
    str    = "<</X <48656C6C6F> >>"
    tokens = [ {:X => "\x48\x65\x6C\x6C\x6F"} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a dictionary with an embedded dictionary" do
    str    = "<</X << /Y 1 >> >>"
    tokens = [ {:X => {:Y => 1}} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a dictionary with a false value" do
    str    = "<</Title false>>"
    tokens = [ {:Title => false} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a simple dictionary without space between value and key" do
    str    = "<</One 1/Two 2>>"
    tokens = [ {:One => 1, :Two => 2} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse operators" do
    str    = "q Q"
    tokens = %w{ q Q }
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse three char operators before one char" do
    str    = "B BDC B"
    tokens = %w{ B BDC B }
    PDF::Reader::NewParser.parse(str).should == tokens
  end
end
