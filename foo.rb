require 'parslet'
require 'rspec'
=begin
module PDF
  class Reader
    class Token < Treetop::Runtime::SyntaxNode
      def to_ary
        [self.text_value]
      end
    end

    class ArrayNode < Treetop::Runtime::SyntaxNode
      def to_ary
        elements[1].elements.flatten.select { |obj|
          !obj.is_a?(Treetop::Runtime::SyntaxNode)
        }
      end
    end

    class DictNode < Treetop::Runtime::SyntaxNode
      def to_ary
        ret = elements[1].elements.flatten.select { |obj|
          !obj.is_a?(Treetop::Runtime::SyntaxNode)
        }
        [ Hash[*ret] ]
      end
    end

    class Integer < Treetop::Runtime::SyntaxNode
      def to_ary
        [ text_value.to_i ]
      end
    end

    class Float < Treetop::Runtime::SyntaxNode
      def to_ary
        [ text_value.to_f ]
      end
    end

    class Name < Treetop::Runtime::SyntaxNode
      def to_ary
        [ elements[1].text_value.to_sym ]
      end
    end

    class BooleanTrue < Treetop::Runtime::SyntaxNode
      def to_ary
        [ true ]
      end
    end

    class BooleanFalse < Treetop::Runtime::SyntaxNode
      def to_ary
        [ false ]
      end
    end

    class NullNode < Treetop::Runtime::SyntaxNode
      def to_ary
        [ nil ]
      end
    end

    class HexString < Treetop::Runtime::SyntaxNode
      def to_ary
        [
          elements[1].text_value.scan(/../).map { |i| i.hex.chr }.join
        ]
      end
    end

    class LiteralString < Treetop::Runtime::SyntaxNode
      def to_ary
        [elements[1].text_value]
      end
    end
  end
end

=end

class PdfParser < Parslet::Parser

  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  rule(:doc) { ( string_literal | string_hex | array | dict | name | boolean | null | float | integer | space ).repeat }

  rule(:string_literal) { str("(") >> match('[^\(\)]').repeat.as(:string_literal) >> str(")") }

  rule(:string_hex)     { str("<") >> match('[A-Fa-f0-9]').repeat.as(:string_hex) >> str(">") }

  rule(:array)          { str("[") >> doc.as(:array) >> str("]") }

  rule(:dict)           { str("<<") >> doc.as(:dict) >> str(">>") }

  rule(:name)           { str('/') >> match('[A-Za-z]').repeat.as(:name) }

  rule(:float)          { (match('[0-9]').repeat(1) >> str('.') >> match('[0-9]').repeat(1) ).as(:float) }

  rule(:integer)        { match('[0-9]').repeat(1).as(:integer) }

  rule(:boolean)        { (str("true") | str("false")).as(:boolean)}

  rule(:null)           { str('null').as(:null) }

  root(:doc)
end

class PdfTransform < Parslet::Transform
  rule(:string_literal => simple(:value)) { value }

  rule(:string_hex => simple(:value)) {
    value.scan(/../).map { |i| i.hex.chr }.join
  }

  rule(:name => simple(:value)) { value.to_sym }

  rule(:float => simple(:value)) { value.to_f }

  rule(:integer => simple(:value)) { value.to_i }

  rule(:boolean => simple(:value)) { value == "true" }

  rule(:null => simple(:value)) { nil }
end


describe PdfTransform do
  let(:transform) { PdfTransform.new }

  it "transforms a literal string" do
    str = [{ :string_literal => "abc"}]
    transform.apply(str).should == %w{ abc }
  end

  it "transforms a hex string without captials" do
    str = [{ :string_hex => "00ffab"}]
    transform.apply(str).should == [ "\x00\xff\xab" ]
  end

  it "transforms a PDF Name to a ruby symbol" do
    str = [{ :name => "James"}]
    transform.apply(str).should == [ :James ]
  end

  it "transforms a float" do
    str = [{ :float => "1.9"}]
    transform.apply(str).should == [ 1.9 ]
  end

  it "transforms an int" do
    str = [{ :float => "10"}]
    transform.apply(str).should == [ 10 ]
  end

  it "transforms a true boolean" do
    str = [{ :boolean => "true"}]
    transform.apply(str).should == [ true ]
  end

  it "transforms a false boolean" do
    str = [{ :boolean => "false"}]
    transform.apply(str).should == [ false ]
  end

  it "transforms a null" do
    str = [{ :null => "null"}]
    transform.apply(str).should == [ nil ]
  end
end

describe PdfParser do
  let(:parser) { PdfParser.new }

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

  it "should parse a hex string without captials" do
    str = "<00ffab>"
    ast = [ { :string_hex => "00ffab" } ]
    parser.parse(str).should == ast
  end

  it "should parse a hex string with captials" do
    str = " <00FFAB> "
    ast = [ { :string_hex => "00FFFB" } ]
    parser.parse(str).should == ast
  end

  it "should parse two hex strings" do
    str = " <00FF> <2030>"
    ast = [ { :string_hex => "00FF"}, {:string_hex => "2030"} ]
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

  it "should parse a float" do
    str = "1.1"
    ast = [ { :float => "1.1" } ]
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
    ast = [ { :name => :James } ]
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
end
