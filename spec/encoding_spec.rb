# typed: false
# coding: utf-8

describe PDF::Reader::Encoding do
  describe "initialisation" do

    context "when the encoding is unrecognised" do
      it "returns a new encoding object" do
        expect(PDF::Reader::Encoding.new("FakeEncoding")).to be_a_kind_of(PDF::Reader::Encoding)
        expect(PDF::Reader::Encoding.new(nil)).to be_a_kind_of(PDF::Reader::Encoding)
      end
    end

    context "when the encoding is WinAnsi" do
      it "returns a new encoding object" do
        win =  {:Encoding => :WinAnsiEncoding}
        expect(PDF::Reader::Encoding.new(win)).to  be_a_kind_of(PDF::Reader::Encoding)
      end
    end

    context "when the encoding is WinAnsi with an even-count differences table" do
      let!(:enc) do
        PDF::Reader::Encoding.new(:Encoding    => :WinAnsiEncoding,
                                  :Differences => [25, :A, 26, :B]
                                )
      end
      it "returns a new encoding object" do
        expect(enc).to be_a_kind_of(PDF::Reader::Encoding)
      end
      it "records the differences" do
        expect(enc.differences).to be_a_kind_of(Hash)
        expect(enc.differences[25]).to eql(:A)
        expect(enc.differences[26]).to eql(:B)
      end
    end

    context "when the encoding is WinAnsi with a odd-count differences table" do
      let!(:enc) do
        PDF::Reader::Encoding.new(:Encoding    => :WinAnsiEncoding,
                                  :Differences => [25, :A, 26, :B]
                                )
      end
      it "returns a new encoding object" do
        expect(enc).to be_a_kind_of(PDF::Reader::Encoding)
      end
      it "records the differences" do
        expect(enc.differences).to be_a_kind_of(Hash)
        expect(enc.differences[25]).to eql(:A)
        expect(enc.differences[26]).to eql(:B)
      end
    end

  end

  describe "#to_utf8" do

    context "when the encoding is WinAnsi with an even-count differences table" do
      let!(:enc) do
        PDF::Reader::Encoding.new(:Encoding    => :WinAnsiEncoding,
                                  :Differences => [1, :A]
                                )
      end
      it "converts recognised characters from the differences to utf-8" do
        expect(enc.to_utf8("\001")).to eql("A")
      end
      it "converts unknown characters with 'unknown char'" do
        expect(enc.to_utf8("\002")).to eql("▯")
      end
    end

    context "when the encoding is Identity-H" do
      it "returns utf-8 squares" do
        e = PDF::Reader::Encoding.new("Identity-H")
        [
          {:expert => "\x22",             :utf8 => ""},
          {:expert => "\x22\xF7",         :utf8 => [0x25AF].pack("U*")},
          {:expert => "\x22\xF7\x22\xF7", :utf8 => [0x25AF,0x25AF].pack("U*")}
        ].each do |vals|
          result = e.to_utf8(vals[:expert])
          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])
        end
      end
    end

    context "when the encoding is Identity-V" do
      it "returns utf-8 squares if to_utf8 is called without a cmap" do
        e = PDF::Reader::Encoding.new("Identity-V")
        [
          {:expert => "\x22",             :utf8 => ""},
          {:expert => "\x22\xF7",         :utf8 => [0x25AF].pack("U*")},
          {:expert => "\x22\xF7\x22\xF7", :utf8 => [0x25AF,0x25AF].pack("U*")}
        ].each do |vals|
          result = e.to_utf8(vals[:expert])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])
        end
      end
    end

    context "when the encoding is MacExpert" do
      it "correctly converts various expert strings to utf-8" do
        e = PDF::Reader::Encoding.new(:MacExpertEncoding)
        [
          {:expert => "\x22", :utf8 => [0xF6F8].pack("U*")},
          {:expert => "\x62", :utf8 => [0xF762].pack("U*")},
          {:expert => "\xBE", :utf8 => [0xF7E6].pack("U*")},
          {:expert => "\xF7", :utf8 => [0xF6EF].pack("U*")}
        ].each do |vals|
          result = e.to_utf8(vals[:expert])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])
        end
      end
    end
    context "when the encoding is MacExpert with differences" do
      it "correctly converts various mac expert strings" do
        e = PDF::Reader::Encoding.new(:MacExpertEncoding)
        e.differences = [0xEE, :A]
        [
          {:mac => "\x22\xEE", :utf8 => [0xF6F8, 0x41].pack("U*")}
        ].each do |vals|

          result = e.to_utf8(vals[:mac])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is MacRoman" do
      it "correctly converts various strings to utf-8" do
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
          expect(result).to eql(vals[:utf8])

          expect(result.encoding.to_s).to eql("UTF-8")
        end
      end
    end

    context "when the encoding is MacRoman with differences" do
      it "correctly converts various strings" do
        e = PDF::Reader::Encoding.new(:MacRomanEncoding)
        e.differences = [0xEE, :A]
        [
          {:mac => "\x24\xEE", :utf8 => [0x24, 0x41].pack("U*")}, # dollar sign, A
        ].each do |vals|

          result = e.to_utf8(vals[:mac])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end

    context "when the encoding is PdfDoc" do
      it "correctly converts various strings to utf-8" do
        e = PDF::Reader::Encoding.new(:PDFDocEncoding)
        [
          {:pdf => "\x22", :utf8 => [0x22].pack("U*")},
          {:pdf => "\x62", :utf8 => [0x62].pack("U*")},
          {:pdf => "\xA0", :utf8 => [0x20AC].pack("U*")},
          {:pdf => "\x94", :utf8 => [0xFB02].pack("U*")}
        ].each do |vals|
          result = e.to_utf8(vals[:pdf])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])
        end
      end
    end
    context "when the encoding is PdfDoc with differences" do
      it "correctly converts various strings" do
        e = PDF::Reader::Encoding.new(:PDFDocEncoding)
        e.differences = [0xEE, :A]
        [
          {:pdf => "\x22\xEE", :utf8 => [0x22, 0x41].pack("U*")}
        ].each do |vals|

          result = e.to_utf8(vals[:pdf])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is StandardEncoding" do
      it "correctly converts various standard strings to utf-8" do
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

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is StandardEncoding with differences" do
      it "correctly converts various strings to utf-8" do
        e = PDF::Reader::Encoding.new(:StandardEncoding)
        e.differences = [0xEE, :A]
        [
          {:std => "\x60\xEE", :utf8 => [0x2018, 0x41].pack("U*")}, # ", A
        ].each do |vals|

          result = e.to_utf8(vals[:std])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is Symbol" do
      it "correctly converts various symbol strings to utf-8" do
        e = PDF::Reader::Encoding.new(:SymbolEncoding)
        [
          {:symbol => "\x41", :utf8 => [0x0391].pack("U*")}, # alpha
          {:symbol => "\x42", :utf8 => [0x0392].pack("U*")}, # beta
          {:symbol => "\x47", :utf8 => [0x0393].pack("U*")}, # gamma
          {:symbol => "123",  :utf8 => "123"},
          {:symbol => "\xA0", :utf8 => [0x20AC].pack("U*")}, # € sign
        ].each do |vals|
          result = e.to_utf8(vals[:symbol])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is Symbol with differences" do
      it "correctly converts various symbol strings when a differences table is specified" do
        e = PDF::Reader::Encoding.new(:SymbolEncoding)
        e.differences = [0xEE, :A]
        [
          {:symbol => "\x41\xEE", :utf8 => [0x0391, 0x41].pack("U*")}, # alpha, A
        ].each do |vals|

          result = e.to_utf8(vals[:symbol])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is WinAnsi" do
      it "correctly converts various win-1252 strings to utf-8" do
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
          expect(result).to eql(vals[:utf8])

          expect(result.encoding.to_s).to eql("UTF-8")
        end
      end
    end
    context "when the encoding is WinAnsi with differences" do
      it "correctly converts various strings" do
        e = PDF::Reader::Encoding.new(:WinAnsiEncoding)
        e.differences = [0xEE, :A]
        [
          {:win => "abc", :utf8 => "abc"},
          {:win => "ABC", :utf8 => "ABC"},
          {:win => "123", :utf8 => "123"},
          {:win => "ABC\xEE", :utf8 => "ABCA"}
        ].each do |vals|
          result = e.to_utf8(vals[:win])
          expect(result).to eql(vals[:utf8])

          expect(result.encoding.to_s).to eql("UTF-8")
        end
      end
    end
    context "when the encoding is ZaphDingbats" do
      it "correctly converts various dingbats strings to utf-8" do
        e = PDF::Reader::Encoding.new(:ZapfDingbatsEncoding)
        [
          {:dingbats => "\x22", :utf8 => [0x2702].pack("U*")}, # scissors
          {:dingbats => "\x25", :utf8 => [0x260E].pack("U*")}, # telephone
          {:dingbats => "\xAB", :utf8 => [0x2660].pack("U*")}, # spades
          {:dingbats => "\xDE", :utf8 => [0x279E].pack("U*")}, # ->
        ].each do |vals|
          result = e.to_utf8(vals[:dingbats])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end
    context "when the encoding is ZaphDingbats with differences" do
      it "correctly converts various dingbats strings when a differences table is specified" do
        e = PDF::Reader::Encoding.new(:ZapfDingbatsEncoding)
        e.differences = [0xEE, :A]
        [
          {:dingbats => "\x22\xEE", :utf8 => [0x2702, 0x41].pack("U*")}, # scissors
        ].each do |vals|

          result = e.to_utf8(vals[:dingbats])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])

        end
      end
    end

    context "when the encoding is UTF16" do
      it "correctly converts various PDFDoc strings to utf-8" do
        e = PDF::Reader::Encoding.new(:UTF16Encoding)
        [
          {:utf16 => "\x00\x41", :utf8 => [0x41].pack("U*")},
          {:utf16 => "\x20\x22", :utf8 => [0x2022].pack("U*")},
          {:utf16 => "\x00\x41", :utf8 => [0x41].pack("U*")},
          {:utf16 => "\x20\x22", :utf8 => [0x2022].pack("U*")}
        ].each do |vals|
          result = e.to_utf8(vals[:utf16])

          expect(result.encoding.to_s).to eql("UTF-8")
          vals[:utf8].force_encoding("UTF-8")

          expect(result).to eql(vals[:utf8])
        end
      end
    end
  end

  describe "#int_to_utf8_string" do

    context "when the encoding is WinAnsi" do
      let!(:enc) {
        PDF::Reader::Encoding.new(:Encoding => :WinAnsiEncoding)
      }
      it "converts a int glyph code to the relevant utf-8 string" do
        expect(enc.int_to_utf8_string(65)).to eq("A")
      end
    end
  end
end
