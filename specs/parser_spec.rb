
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

  specify "should be able to decode streams that use FlateDecode" do
    decoded_stream = "\n0.000 0.000 0.000 rg\n0.000 0.000 0.000 RG\nq\n1 w\nQ\nq\n1 w\nQ\nq\nq\n430.000 0 0 787.000 300.000 50.000 cm\n/I0 Do\nQ\nq\n1.000 0.000 0.000 rg\n1.000 0.000 0.000 RG\n72.000 0.000 81.156 792.000 re f\n1.000 1.000 1.000 rg\n1.000 1.000 1.000 RG\nBT 0.000 1.000 -1.000 0.000 137.303 70.000 Tm /F1 72.0 Tf 0 Tr (PDF::Writer for Ruby) Tj ET\n1 w\nQ\nBT 536.664 711.216 Td /F1 24.0 Tf 0 Tr (\n) Tj ET\nBT 170.016 684.432 Td /F1 24.0 Tf 0 Tr (Native Ruby PDF Document Creation\n) Tj ET\nBT 540.220 662.112 Td /F1 20.0 Tf 0 Tr (\n) Tj ET\nBT 357.440 639.792 Td /F1 20.0 Tf 0 Tr (The Ruby PDF Project\n) Tj ET\nBT 237.480 617.472 Td ET\nq\n0.000 0.000 1.000 rg\n0.000 0.000 1.000 RG\n1.116 w [ ] 0 d\nBT 237.480 617.472 Td 0.000 Tw /F1 20.0 Tf 0 Tr (http://rubyforge.org/projects/ruby-pdf) Tj ET\n237.480 615.798 m\n540.220 615.798 l S\n1 w\nQ\nBT 540.220 617.472 Td /F1 20.0 Tf 0 Tr (\n) Tj ET\nBT 436.340 595.152 Td 0.000 Tw /F1 20.0 Tf 0 Tr (version 1.1.2\n) Tj ET\nBT 541.998 575.064 Td 0.000 Tw /F1 18.0 Tf 0 Tr (\n) Tj ET\nBT 368.748 554.976 Td 0.000 Tw /F1 18.0 Tf 0 Tr (Copyright \251 2003\2262005\n) Tj ET\nBT 437.508 534.888 Td 0.000 Tw ET\nq\n0.000 0.000 1.000 rg\n0.000 0.000 1.000 RG\n1.0044 w [ ] 0 d\nBT 437.508 534.888 Td /F1 18.0 Tf 0 Tr (Austin Ziegler) Tj ET\n437.508 533.381 m\n541.998 533.381 l S\n1 w\nQ\nBT 541.998 534.888 Td /F1 18.0 Tf 0 Tr (\n) Tj ET\n1 w\nQ"

    buffer = PDF::Reader::Buffer.new(File.new(File.dirname(__FILE__) + "/data/pdfwriter-manual.pdf"))
    xref = PDF::Reader::XRef.new(buffer)
    buffer.seek(1445)
    parser = PDF::Reader::Parser.new(buffer, xref)
    obj, stream = parser.object(7, 0)
    obj.should be_a_kind_of(Hash)
    stream.should eql(decoded_stream)
  end

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
