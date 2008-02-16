$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'


context "PDF::Reader::Font" do

  specify "should select a sensible encoding when set to a symbol font" do
    f = PDF::Reader::Font.new
    f.basefont = "Arial"
    f.encoding.should be_nil

    f.basefont = "Symbol"
    f.encoding.should be_a_kind_of(PDF::Reader::Encoding::SymbolEncoding)

    f.basefont = "ZapfDingbats"
    f.encoding.should be_a_kind_of(PDF::Reader::Encoding::ZapfDingbatsEncoding)
  end

  specify "should correctly attempt to convert various strings to utf-8" do
    f = PDF::Reader::Font.new
    # TODO: create a mock encoding object and ensure to_utf8 is called on it
  end

  specify "should return the same type when to_utf8 is called" do
    f = PDF::Reader::Font.new
    f.to_utf8("abc").should be_a_kind_of(String)
    f.to_utf8(["abc"]).should be_a_kind_of(Array)
    f.to_utf8(123).should be_a_kind_of(Numeric)
  end

  specify "should use an encoding of StandardEncoding if none has been specified" do
    f = PDF::Reader::Font.new
    str = "abc\xA8"
    f.to_utf8(str).should eql("abc\xC2\xA4")
  end

end
