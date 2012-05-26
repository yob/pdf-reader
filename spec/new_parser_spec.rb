# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::NewParser do
  let(:parser) { PDF::Reader::NewParser.new }

  it "should parse a literal string" do
    str = "(abc)"
    ast = [{ :string_literal => "abc" }]
    parser.parse(str).should == ast
  end

  it "should parse two literal strings" do
    str    = "(abc) (def)"
    ast = [{ :string_literal => "abc" }, { :string_literal => "def"}]
    parser.parse(str).should == ast
  end

  it "should parse a literal string with capitals" do
    str    = "(ABC)"
    ast = [{ :string_literal => "ABC" }]
    parser.parse(str).should == ast
  end

  it "should parse a literal string with spaces" do
    str    = " (abc) "
    ast = [{ :string_literal => "abc" }]
    parser.parse(str).should == ast
  end

  it "should parse an empty string" do
    str    = "()"
    ast = [{ :string_literal => [] }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing spaces" do
    str    = "(this is a string)"
    ast = [{ :string_literal => "this is a string" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped newline" do
    str    = "(this \\n is a string)"
    ast = [{ :string_literal => "this \\n is a string" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped tab" do
    str    = "(x \\t x)"
    ast = [{ :string_literal => "x \\t x" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped octal" do
    str    = "(x \\101 x)"
    ast = [{ :string_literal => "x \\101 x" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped octal" do
    str    = "(x \\61 x)"
    ast = [{ :string_literal => "x \\61 x" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped digit" do
    str    = "(x \\1 x)"
    ast = [{ :string_literal => "x \\1 x" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped left paren" do
    str    = '(x \( x)'
    ast = [{ :string_literal => 'x \( x' }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an escaped right paren" do
    str    = "(x \\) x)"
    ast = [{ :string_literal => "x \\) x" }]
    parser.parse(str).should == ast
  end

  it "should parse a string containing an balanced nested parens" do
    str    = "((x))"
    ast = [{ :string_literal => [{:string_literal => "x"}] }]
    parser.parse(str).should == ast
  end

  it "should parse a hex string without captials" do
    str = "<00ffab>"
    ast = [ { :string_hex => "00ffab" } ]
    parser.parse(str).should == ast
  end

  it "should parse a hex string with captials" do
    str = " <00FFAB> "
    ast = [ { :string_hex => "00FFAB" } ]
    parser.parse(str).should == ast
  end

  it "should parse two hex strings" do
    str = " <00FF> <2030>"
    ast = [ { :string_hex => "00FF"}, {:string_hex => "2030"} ]
    parser.parse(str).should == ast
  end

  it "should parse a hex string with whitespace" do
    str = " <00FF\n2030>"
    ast = [ { :string_hex => "00FF\n2030"} ]
    parser.parse(str).should == ast
  end

  it "should parse an integer" do
    str = "9"
    ast = [ { :integer => "9" } ]
    parser.parse(str).should == ast
  end

  it "should parse a double digit integer" do
    str = "99"
    ast = [ { :integer => "99" } ]
    parser.parse(str).should == ast
  end

  it "should parse a triple digit integer" do
    str = "123"
    ast = [ { :integer => "123" } ]
    parser.parse(str).should == ast
  end

  it "should parse an integer with spaces" do
    str = " 19 "
    ast = [ { :integer => "19" } ]
    parser.parse(str).should == ast
  end

  it "should parse an integer with a + sign" do
    str = "+15"
    ast = [ { :integer => "+15" } ]
    parser.parse(str).should == ast
  end

  it "should parse an integer with a - sign" do
    str = "-34"
    ast = [ { :integer => "-34" } ]
    parser.parse(str).should == ast
  end

  it "should parse a float" do
    str = "1.1"
    ast = [ { :float => "1.1" } ]
    parser.parse(str).should == ast
  end

  it "should parse a float with a + sign" do
    str = "+19.1"
    ast = [ { :float => "+19.1" } ]
    parser.parse(str).should == ast
  end

  it "should parse a float with a - sign" do
    str = "-73.2"
    ast = [ { :float => "-73.2" } ]
    parser.parse(str).should == ast
  end

  it "should parse a float with spaces" do
    str = " 19.9 "
    ast = [ { :float => "19.9" } ]
    parser.parse(str).should == ast
  end

  it "should parse a pdf name" do
    str = "/James"
    ast = [ { :name => "James" } ]
    parser.parse(str).should == ast
  end

  it "should parse a pdf name with spaces" do
    str = " /James "
    ast = [ { :name => "James" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with odd but legal characters" do
    str = "/A;Name_With-Various***Characters?"
    ast = [ { :name => "A;Name_With-Various***Characters?" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name that looks like a float" do
    str = "/1.2"
    ast = [ { :name => "1.2" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with dollar signs" do
    str = "/$$"
    ast = [ { :name => "$$" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with an @ sign" do
    str = "/@pattern"
    ast = [ { :name => "@pattern" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with an decimal point" do
    str = "/.notdef"
    ast = [ { :name => ".notdef" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with an encoded space" do
    str = "/James#20Healy"
    ast = [ { :name => "James#20Healy" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with an encoded #" do
    str = "/James#23Healy"
    ast = [ { :name => "James#23Healy" } ]
    parser.parse(str).should == ast
  end

  it "should parse a name with an encoded m" do
    str = "/Ja#6des"
    ast = [ { :name => "Ja#6des" } ]
    parser.parse(str).should == ast
  end

  it "should parse a true boolean" do
    str = "true"
    ast = [ {:boolean => "true" } ]
    parser.parse(str).should == ast
  end

  it "should parse a false boolean" do
    str = "false"
    ast = [ { :boolean => "false" } ]
    parser.parse(str).should == ast
  end

  it "should parse a null" do
    str = "null"
    ast = [ { :null => "null" } ]
    parser.parse(str).should == ast
  end

  it "should parse an array of ints" do
    str = "[ 1 2 3 4 ]"
    ast = [
      { :array => [
        {:integer => "1"},
        {:integer => "2"},
        {:integer => "3"},
        {:integer => "4"}
        ]
      }
    ]
    parser.parse(str).should == ast
  end

  it "should parse an array of indirect objects" do
    str = "[ 10 0 R 12 0 R ]"
    ast = [
      { :array => [
        {:indirect => "10 0 R"},
        {:indirect => "12 0 R"}
        ]
      }
    ]
    parser.parse(str).should == ast
  end

  it "should parse a simple dictionary" do
    str = "<</One 1 /Two 2>>"
    ast = [
      { :dict => [
        {:name => "One"},
        {:integer => "1"},
        {:name => "Two"},
        {:integer => "2"}
        ]
      }
    ]
    parser.parse(str).should == ast
  end

  it "should parse a dictionary with an embedded hex string" do
    str = "<</X <48656C6C6F> >>"
    ast = [
      { :dict => [
        {:name => "X"},
        {:string_hex => "48656C6C6F"}
        ]
      }
    ]
    parser.parse(str).should == ast
  end

  it "parses an indirect reference" do
    str = "1 0 R"
    ast = [ {:indirect => "1 0 R"} ]
    parser.parse(str).should == ast
  end

  it "parses the 'obj' keyword" do
    str = "obj"
    ast = [ {:keyword => "obj"} ]
    parser.parse(str).should == ast
  end

  it "parses the 'endobj' keyword" do
    str = "endobj"
    ast = [ {:keyword => "endobj"} ]
    parser.parse(str).should == ast
  end

  it "parses the 'stream' keyword" do
    str = "stream"
    ast = [ {:keyword => "stream"} ]
    parser.parse(str).should == ast
  end

  it "parses the 'endstream' keyword" do
    str = "endstream"
    ast = [ {:keyword => "endstream"} ]
    parser.parse(str).should == ast
  end
end
