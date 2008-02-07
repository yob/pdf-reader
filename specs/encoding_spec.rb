# coding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context "The PDF::Reader::Encoding class" do

  specify "should return a new encoding object on request, or raise an error if unrecognised" do
    PDF::Reader::Encoding.factory("Identity-H").should be_a_kind_of(PDF::Reader::Encoding::IdentityH)
    PDF::Reader::Encoding.factory("WinAnsiEncoding").should be_a_kind_of(PDF::Reader::Encoding::WinAnsiEncoding)
    lambda { PDF::Reader::Encoding.factory("FakeEncoding")}.should raise_error(PDF::Reader::UnsupportedFeatureError)
    PDF::Reader::Encoding.factory(nil).should be_nil
  end

  specify "should raise an exception if to_utf8 is called" do
    e = PDF::Reader::Encoding.new
    lambda { e.to_utf8("test")}.should raise_error(RuntimeError)
  end
end

context "The PDF::Reader::Encoding::IdentityH class" do

  specify "should raise an exception if to_utf8 is called without a cmap" do
    e = PDF::Reader::Encoding::IdentityH.new
    lambda { e.to_utf8("test")}.should raise_error(ArgumentError)
  end

  specify "should convert an IdentityH encoded string into UTF-8" do
    e = PDF::Reader::Encoding::IdentityH.new
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x00\x01\x00\x02", cmap)
    
    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end
  end

end

context "The PDF::Reader::Encoding::MacRomanEncoding class" do

  specify "should correctly convert various mac roman strings to utf-8" do
    e = PDF::Reader::Encoding::MacRomanEncoding.new
    [
      {:mac => "abc", :utf8 => "abc"},
      {:mac => "ABC", :utf8 => "ABC"},
      {:mac => "123", :utf8 => "123"},
      {:mac => "\x24", :utf8 => "\x24"},         # dollar sign
      {:mac => "\xDB", :utf8 => "\xE2\x82\xAC"}, # € sign
      {:mac => "\xD8", :utf8 => "\xC3\xBF"},     # ÿ sign
      {:mac => "\xE4", :utf8 => "\xE2\x80\xB0"}, # ‰  sign
      {:mac => "\xFD", :utf8 => "\xCB\x9D"}      # ˝ sign
    ].each do |vals| 
      result = e.to_utf8(vals[:mac])
      result.should eql(vals[:utf8]) 
      
      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
      end
    end
  end
end

context "The PDF::Reader::Encoding::WinAnsiEncoding class" do

  specify "should correctly convert various win-1252 strings to utf-8" do
    e = PDF::Reader::Encoding::WinAnsiEncoding.new
    [
      {:win => "abc", :utf8 => "abc"},
      {:win => "ABC", :utf8 => "ABC"},
      {:win => "123", :utf8 => "123"},
      {:win => "\x24", :utf8 => "\x24"},         # dollar sign
      {:win => "\x80", :utf8 => "\xE2\x82\xAC"}, # € sign
      {:win => "\x82", :utf8 => "\xE2\x80\x9A"}, # ‚ sign
      {:win => "\x83", :utf8 => "\xC6\x92"},     # ƒ sign
      {:win => "\x9F", :utf8 => "\xC5\xB8"}      # Ÿ sign
    ].each do |vals| 
      result = e.to_utf8(vals[:win])
      result.should eql(vals[:utf8]) 
      
      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
      end
    end
  end
end
