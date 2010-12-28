# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Encoding do

  it "should return a new encoding object on request, or raise an error if unrecognised" do
    lambda { PDF::Reader::Encoding.new("FakeEncoding")}.should raise_error(PDF::Reader::UnsupportedFeatureError)
    PDF::Reader::Encoding.new(nil).should be_a_kind_of(PDF::Reader::Encoding)
  end

  it "should return a new encoding object on request, or raise an error if unrecognised" do
    win =  {:Encoding => :WinAnsiEncoding}
    fake = {:Encoding => :FakeEncoding}
    PDF::Reader::Encoding.new(win).should be_a_kind_of(PDF::Reader::Encoding)
    lambda { PDF::Reader::Encoding.new(fake)}.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end

  it "should return a new encoding object with a differences table on request" do
    win =  {
             :Encoding    => :WinAnsiEncoding,
             :Differences => [25, :A, 26, :B]
           }
    enc = PDF::Reader::Encoding.new(win)
    enc.should be_a_kind_of(PDF::Reader::Encoding)
    enc.differences.should be_a_kind_of(Hash)
    enc.differences[25].should eql(:A)
    enc.differences[26].should eql(:B)
  end

  it "should return a new encoding object with a differences table on request" do
    win =  {
             :Encoding    => :WinAnsiEncoding,
             :Differences => [25, :A, :B]
           }
    enc = PDF::Reader::Encoding.new(win)
    enc.should be_a_kind_of(PDF::Reader::Encoding)
    enc.differences.should be_a_kind_of(Hash)
    enc.differences[25].should eql(:A)
    enc.differences[26].should eql(:B)
  end

  it "should correctly replace control characters with 'unknown char' when there's no applicable difference table entry" do
    win =  {
             :Encoding    => :WinAnsiEncoding,
             :Differences => [1, :A,]
           }
    enc = PDF::Reader::Encoding.new(win)
    enc.to_utf8("\002").should eql("▯")
  end
end

describe "The PDF::Reader::Encoding::IdentityH class" do

  it "should return utf-8 squares if to_utf8 is called without a cmap" do
    e = PDF::Reader::Encoding.new("Identity-H")
    [
      {:expert => "\x22",             :utf8 => ""},
      {:expert => "\x22\xF7",         :utf8 => [0x25AF].pack("U*")},
      {:expert => "\x22\xF7\x22\xF7", :utf8 => [0x25AF,0x25AF].pack("U*")}
    ].each do |vals|
      result = e.to_utf8(vals[:expert])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])
    end
  end

  it "should convert an IdentityH encoded string into UTF-8" do
    e = PDF::Reader::Encoding.new("Identity-H")
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x00\x01\x00\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end
  end

end

describe "The PDF::Reader::Encoding::MacExpertEncoding class" do

  it "should correctly convert various expert strings to utf-8" do
    e = PDF::Reader::Encoding.new(:MacExpertEncoding)
    [
      {:expert => "\x22", :utf8 => [0xF6F8].pack("U*")},
      {:expert => "\x62", :utf8 => [0xF762].pack("U*")},
      {:expert => "\xBE", :utf8 => [0xF7E6].pack("U*")},
      {:expert => "\xF7", :utf8 => [0xF6EF].pack("U*")}
    ].each do |vals|
      result = e.to_utf8(vals[:expert])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])
    end
  end

  it "should correctly convert various mac expert strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:MacExpertEncoding)
    e.differences = [0xEE, :A]
    [
      {:mac => "\x22\xEE", :utf8 => [0xF6F8, 0x41].pack("U*")}
    ].each do |vals|

      result = e.to_utf8(vals[:mac])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:MacExpertEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end

  end
end

describe "The PDF::Reader::Encoding::MacRomanEncoding class" do

  it "should correctly convert various mac roman strings to utf-8" do
    e = PDF::Reader::Encoding.new(:MacRomanEncoding)
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

  it "should correctly convert various mac roman strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:MacRomanEncoding)
    e.differences = [0xEE, :A]
    [
      {:mac => "\x24\xEE", :utf8 => [0x24, 0x41].pack("U*")}, # dollar sign, A
    ].each do |vals|

      result = e.to_utf8(vals[:mac])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:MacRomanEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end

  end
end

describe "The PDF::Reader::Encoding::PDFDocEncoding class" do

  it "should correctly convert various PDFDoc strings to utf-8" do
    e = PDF::Reader::Encoding.new(:PDFDocEncoding)
    [
      {:pdf => "\x22", :utf8 => [0x22].pack("U*")},
      {:pdf => "\x62", :utf8 => [0x62].pack("U*")},
      {:pdf => "\xA0", :utf8 => [0x20AC].pack("U*")},
      {:pdf => "\x94", :utf8 => [0xFB02].pack("U*")}
    ].each do |vals|
      result = e.to_utf8(vals[:pdf])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])
    end
  end

  it "should correctly convert various pdf doc strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:PDFDocEncoding)
    e.differences = [0xEE, :A]
    [
      {:pdf => "\x22\xEE", :utf8 => [0x22, 0x41].pack("U*")}
    ].each do |vals|

      result = e.to_utf8(vals[:pdf])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:PDFDocEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end

  end
end

describe "The PDF::Reader::Encoding::StandardEncoding class" do

  it "should correctly convert various standard strings to utf-8" do
    e = PDF::Reader::Encoding.new(:StandardEncoding)
    [
      {:standard => "abc",  :utf8 => "abc"},
      {:standard => "ABC",  :utf8 => "ABC"},
      {:standard => "123",  :utf8 => "123"},
      {:standard => "\x60", :utf8 => [0x2018].pack("U*")}, # "
      {:standard => "\xA4", :utf8 => [0x2044].pack("U*")}, # fraction sign
      {:standard => "\xBD", :utf8 => [0x2030].pack("U*")}, # per mile sign
      {:standard => "\xFA", :utf8 => [0x0153].pack("U*")}
    ].each do |vals|
      result = e.to_utf8(vals[:standard])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert various standard strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:StandardEncoding)
    e.differences = [0xEE, :A]
    [
      {:std => "\x60\xEE", :utf8 => [0x2018, 0x41].pack("U*")}, # ", A
    ].each do |vals|

      result = e.to_utf8(vals[:std])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:StandardEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end

  end
end

describe "The PDF::Reader::Encoding::SymbolEncoding class" do

  it "should correctly convert various symbol strings to utf-8" do
    e = PDF::Reader::Encoding.new(:SymbolEncoding)
    [
      {:symbol => "\x41", :utf8 => [0x0391].pack("U*")}, # alpha
      {:symbol => "\x42", :utf8 => [0x0392].pack("U*")}, # beta
      {:symbol => "\x47", :utf8 => [0x0393].pack("U*")}, # gamma
      {:symbol => "123",  :utf8 => "123"},
      {:symbol => "\xA0", :utf8 => [0x20AC].pack("U*")}, # € sign
    ].each do |vals|
      result = e.to_utf8(vals[:symbol])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert various symbol strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:SymbolEncoding)
    e.differences = [0xEE, :A]
    [
      {:symbol => "\x41\xEE", :utf8 => [0x0391, 0x41].pack("U*")}, # alpha, A
    ].each do |vals|

      result = e.to_utf8(vals[:symbol])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:SymbolEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end

  end
end

describe "The PDF::Reader::Encoding::WinAnsiEncoding class" do

  it "should correctly convert various win-1252 strings to utf-8" do
    e = PDF::Reader::Encoding.new(:WinAnsiEncoding)
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

  it "should correctly convert various win-1252 strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:WinAnsiEncoding)
    e.differences = [0xEE, :A]
    [
      {:win => "abc", :utf8 => "abc"},
      {:win => "ABC", :utf8 => "ABC"},
      {:win => "123", :utf8 => "123"},
      {:win => "ABC\xEE", :utf8 => "ABCA"}
    ].each do |vals|
      result = e.to_utf8(vals[:win])
      result.should eql(vals[:utf8])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
      end
    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:WinAnsiEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided for some characters" do
    e = PDF::Reader::Encoding.new(:WinAnsiEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02.00", cmap)

    result.should eql("€1.00")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end
  end
end

describe "The PDF::Reader::Encoding::ZapfDingbatsEncoding class" do

  it "should correctly convert various dingbats strings to utf-8" do
    e = PDF::Reader::Encoding.new(:ZapfDingbatsEncoding)
    [
      {:dingbats => "\x22", :utf8 => [0x2702].pack("U*")}, # scissors
      {:dingbats => "\x25", :utf8 => [0x260E].pack("U*")}, # telephone
      {:dingbats => "\xAB", :utf8 => [0x2660].pack("U*")}, # spades
      {:dingbats => "\xDE", :utf8 => [0x279E].pack("U*")}, # ->
    ].each do |vals|
      result = e.to_utf8(vals[:dingbats])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert various dingbats strings when a differences table is specified" do
    e = PDF::Reader::Encoding.new(:ZapfDingbatsEncoding)
    e.differences = [0xEE, :A]
    [
      {:dingbats => "\x22\xEE", :utf8 => [0x2702, 0x41].pack("U*")}, # scissors
    ].each do |vals|

      result = e.to_utf8(vals[:dingbats])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])

    end
  end

  it "should correctly convert a string into utf-8 when a ToUnicode CMap is provided" do
    e = PDF::Reader::Encoding.new(:ZapfDingbatsEncoding)
    cmap = PDF::Reader::CMap.new("")
    cmap.instance_variable_set("@map",{1 => 0x20AC, 2 => 0x0031})
    result = e.to_utf8("\x01\x02", cmap)

    result.should eql("€1")

    if RUBY_VERSION >= "1.9"
      result.encoding.to_s.should eql("UTF-8")
    end

  end
end

describe "The PDF::Reader::Encoding::UTF16Encoding class" do

  it "should correctly convert various PDFDoc strings to utf-8" do
    e = PDF::Reader::Encoding.new(:UTF16Encoding)
    [
      {:utf16 => "\x00\x41", :utf8 => [0x41].pack("U*")},
      {:utf16 => "\x20\x22", :utf8 => [0x2022].pack("U*")},
      {:utf16 => "\x00\x41", :utf8 => [0x41].pack("U*")},
      {:utf16 => "\x20\x22", :utf8 => [0x2022].pack("U*")}
    ].each do |vals|
      result = e.to_utf8(vals[:utf16])

      if RUBY_VERSION >= "1.9"
        result.encoding.to_s.should eql("UTF-8")
        vals[:utf8].force_encoding("UTF-8")
      end

      result.should eql(vals[:utf8])
    end
  end
end
