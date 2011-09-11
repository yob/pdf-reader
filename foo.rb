require 'treetop'
require 'rspec'

module PDF
  class Reader
    class Token < Treetop::Runtime::SyntaxNode
      def to_ary
        [self.text_value]
      end
    end

    class HexString < Treetop::Runtime::SyntaxNode
      def to_ary
        [elements[1].text_value]
      end
    end

    class LiteralString < Treetop::Runtime::SyntaxNode
      def to_ary
        [elements[1].text_value]
      end
    end
  end
end

class Parser
  Treetop.load(File.join(File.dirname(__FILE__), 'pdf.treetop'))
  @@parser = PdfParser.new

  def self.parse(data)
    # Pass the data over to the parser instance
    tree = @@parser.parse(data)

    # If the AST is nil then there was an error during parsing
    # we need to report a simple error message to help the user
    if tree.nil?
      raise Exception, "Parse error at offset: #{@@parser.index}"
    end

    tree.elements.flatten.select { |obj|
      !obj.is_a?(Treetop::Runtime::SyntaxNode)
    }
  end

end

describe Parser do
  it "should parse a literal string" do
    str    = "(abc)"
    tokens = %w{ abc }
    Parser.parse(str).should == tokens
  end

  it "should parse two literal strings" do
    str    = "(abc) (def)"
    tokens = %w{ abc def }
    Parser.parse(str).should == tokens
  end

  it "should parse a literal string with capitals" do
    str    = "(ABC)"
    tokens = %w{ ABC }
    Parser.parse(str).should == tokens
  end

  it "should parse a literal string with spaces" do
    str    = " (abc) "
    tokens = %w{ abc }
    Parser.parse(str).should == tokens
  end

  it "should parse a hex string without captials" do
    str    = "<00ffab>"
    tokens = %w{ 00ffab }
    Parser.parse(str).should == tokens
  end

  it "should parse a hex string with captials" do
    str    = " <00FFAB> "
    tokens = %w{ 00FFAB }
    Parser.parse(str).should == tokens
  end

  it "should parse two hex strings" do
    str    = " <00FF> <2030>"
    tokens = %w{ 00FF 2030 }
    Parser.parse(str).should == tokens
  end
end
