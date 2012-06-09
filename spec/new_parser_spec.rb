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

  it "should parse an integer" do
    str    = "9"
    tokens = [ 9 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse an integer with spaces" do
    str    = " 19 "
    tokens = [ 19 ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a float" do
    str    = "1.1"
    tokens = [ 1.1 ]
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
    str    = "[ 1 2 3 4 ]"
    tokens = [[ 1, 2, 3, 4 ]]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a simple dictionary" do
    str    = "<</One 1 /Two 2>>"
    tokens = [ {:One => 1, :Two => 2} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end

  it "should parse a simple dictionary without space between value and key" do
    str    = "<</One 1/Two 2>>"
    tokens = [ {:One => 1, :Two => 2} ]
    PDF::Reader::NewParser.parse(str).should == tokens
  end
end
