
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'stringio'
require 'test/unit'
require 'pdf/reader'

module ParserHelper
  def parse_string (r)
    PDF::Reader::Parser.new(PDF::Reader::Buffer.new(sio = StringIO.new(r)), nil).string
  end
end

context "The PDF::Reader::Parser class" do
  include ParserHelper

  specify "should parse a string correctly" do
    parse_string("this is a string)").should eql("this is a string") 
    parse_string("this \\n is a string)").should eql("this \n is a string")
    parse_string("x \\t x)").should eql("x \t x")
    parse_string("x \\101 x)").should eql("x A x")
    parse_string("x \\( x)").should eql("x ( x")
    parse_string("(x)))").should eql("(x)")
    str = <<EOT
x
x \
x)
EOT
    parse_string(str).should eql("x\nx x")
  end

end
