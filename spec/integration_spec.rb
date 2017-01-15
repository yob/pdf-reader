# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

# These specs are a kind of integration spec. They're not unit testing small pieces
# of code, it's just parsing a range of PDF files and ensuring the result is
# consistent. An extra check to make sure parsing these files will continue
# to work for our users.
#
# Where possible, specs that unit test correctly should be written in addition to
# these

describe PDF::Reader, "integration specs" do

  it "should interpret unicode strings correctly" do
    filename = pdf_spec_file("cairo-unicode-short")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to eql("Chunky Bacon")
    end
  end

  it "should interpret Identity-V encoded strings correctly" do
    filename = pdf_spec_file("vertical-text-in-identity-v")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text.split.map(&:strip)).to eql(%w{V e r t i c a l T e x t})
    end
  end

  it "should process text from a the adobe sample file correctly" do
    filename = pdf_spec_file("adobe_sample")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to include("This is a sample PDF file")
      expect(page.text).to include("If you can read this, you already have Adobe Acrobat")
    end
  end

  it "should process text from a dutch PDF correctly" do
    filename = pdf_spec_file("dutch")

    PDF::Reader.open(filename) do |reader|
      expect(reader.pages.size).to eql(3)

      page = reader.page(1)
      expect(page.text).to include("Dit\302\240is\302\240een\302\240pdf\302\240test\302\240van\302\240drie\302\240pagina")
      expect(page.text).to include("’s")
      expect(page.text).to include("Pagina\302\2401")
    end
  end

  it "should process text from a PDF with a difference table correctly" do
    filename = pdf_spec_file("difference_table")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to eql("Goiás")
    end
  end

  it "should process text from a PDF with a content stream that has trailing whitespace" do
    filename = pdf_spec_file("content_stream_trailing_whitespace")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to match(/Tax\s+Invoice/)
    end
  end

  it "should correctly process a PDF with a content stream that is missing an operator (has hanging params)" do
    filename = pdf_spec_file("content_stream_missing_final_operator")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to match(/Locatrix/)
      expect(reader.page(2).text).to match(/Ubuntu/)
    end
  end

  it "should correctly process a PDF with a string containing a high byte (D1) under MacRomanEncoding" do
    # this spec is to detect an hard lock issue some people were encountering on some OSX
    # systems. Real pain to debug.
    filename = pdf_spec_file("hard_lock_under_osx")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text[0,1]).to eql("’")
    end
  end

  it "should not hang when processing a PDF that has a content stream with a broken string" do
    filename = pdf_spec_file("broken_string")

    # this file used to get us into a hard, endless loop. Make sure that doesn't still happen
    Timeout::timeout(3) do
      expect {
        reader = PDF::Reader.new(filename)
        reader.info
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  it "should correctly process a PDF with a stream that has its length specified as an indirect reference" do
    filename = pdf_spec_file("content_stream_with_length_as_ref")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to eql("Hello World")
    end
  end

  # PDF::Reader::XRef#object was saving an incorrect position when seeking. We
  # were saving the current pos of the underlying IO stream, then seeking back
  # to it. This was fine, except when there was still content in the buffer.
  it "should correctly process a PDF with a stream that has its length specified as an indirect reference and uses windows line breaks" do
    filename = pdf_spec_file("content_stream_with_length_as_ref_and_windows_breaks")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to eql("Hello World")
    end
  end

  it "should raise an exception if a content stream refers to a non-existant font" do
    filename = pdf_spec_file("content_stream_refers_to_invalid_font")

    expect {
      reader = PDF::Reader.new(filename)
      reader.page(1).text
    }.to raise_error(PDF::Reader::MalformedPDFError)
  end

  it "should raise an exception if the file is empty" do
    expect {
      PDF::Reader.new(StringIO.new(""))
    }.to raise_error(PDF::Reader::MalformedPDFError)
  end

  it "should correctly process a PDF that uses an ASCII85Decode filter" do
    filename = pdf_spec_file("ascii85_filter")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to match(/Et Iunia se/)
    end
  end

  it "should correctly process a PDF that has an inline image in a content stream with no line breaks" do
    filename = pdf_spec_file("inline_image_single_line_content_stream")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text.strip[0,7]).to eql("WORKING")
    end
  end

  it "should correctly process a PDF that uses Form XObjects to repeat content" do
    filename = pdf_spec_file("form_xobject")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to eql("James Healy")
      expect(reader.page(2).text).to eql("James Healy")
    end
  end

  it "should correctly process a PDF that uses Form XObjects to repeat content" do
    filename = pdf_spec_file("form_xobject_more")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to include("Some regular content")
      expect(reader.page(1).text).to include("James Healy")
      expect(reader.page(2).text).to include("€10")
      expect(reader.page(2).text).to include("James Healy")
    end
  end

  it "should correctly process a PDF that uses indirect Form XObjects to repeat content" do
    filename = pdf_spec_file("indirect_xobject")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).not_to be_nil
    end
  end

  it "should correctly process a PDF that uses multiple content streams for a single page" do
    filename = pdf_spec_file("split_params_and_operator")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to include("My name is")
      expect(reader.page(1).text).to include("James Healy")
    end
  end

  it "should correctly process a PDF that has a single space after the EOF marker" do
    filename = pdf_spec_file("space_after_eof")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to eql("Hello World")
    end
  end

  it "should correctly extract text from a PDF that was generated in open office 3" do
    filename = pdf_spec_file("oo3")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to include("test")
    end
  end

  it "should correctly extract text from a PDF has newlines at the start of a content stream" do
    filename = pdf_spec_file("content_stream_begins_with_newline")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to eql("This file has a content stream that begins with \\n\\n")
    end
  end

  context "encrypted_version2_revision3_blank_user_pass" do
    let(:filename) { pdf_spec_file("encrypted_version2_revision3_blank_user_pass") }

    context "with no user pass" do
      it "correctly extracts text" do
        PDF::Reader.open(filename) do |reader|
          expect(reader.page(1).text).to eql("This sample file is encrypted with no user password")
        end
      end
    end

    context "with the owner pass" do
      it "correctly extracts text"
    end

  end

  context "encrypted_version1_revision2_blank_user_password" do
    let(:filename) { pdf_spec_file("encrypted_version1_revision2_blank_user_password") }

    context "with no user pass" do
      it "correctly extracts text" do
        PDF::Reader.open(filename) do |reader|
          expect(reader.page(1).text).to eql("WOOOOO DOCUMENT!")
        end
      end
    end

    context "with the owner pass" do
      it "correctly extracts text"
    end
  end

  context "encrypted_version1_revision2_no_doc_id" do
    let(:filename) {pdf_spec_file("encrypted_version1_revision2_no_doc_id") }

    context "with no user pass" do
      it "correctly extracts text" do
        PDF::Reader.open(filename) do |reader|
          expect(reader.page(1).text).to eql(
            "This encryped file breaks compatability with the PDF spec because it has no document ID"
          )
        end
      end
    end

    context "with the owner pass" do
      it "correctly extracts text"
    end
  end

  context "encrypted_version2_revision3_user_pass_apples" do
    let(:filename) { pdf_spec_file("encrypted_version2_revision3_user_pass_apples") }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "should correctly extract text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "should correctly extract info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'"
          )
        end
      end
    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "should correctly extract text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "should correctly extract info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'"
          )
        end
      end
    end

    context "with no pass" do
      it "raises an exception" do
        expect {
          PDF::Reader.open(filename) do |reader|
            reader.page(1).text
          end
        }.to raise_error(PDF::Reader::EncryptedPDFError)
      end
    end
  end

  context "encrypted_version4_revision_4user_pass_apples_enc_metadata" do
    let(:filename) { pdf_spec_file("encrypted_version4_revision4_user_pass_apples_enc_metadata") }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "should correctly extract text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "should correctly extract info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate=>"D:20170114125054+11'00'"
          )
        end
      end
    end
    context "with the owner pass" do
      let(:pass) { "password" }

      it "should correctly extract text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "should correctly extract info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate=>"D:20170114125054+11'00'"
          )
        end
      end
    end
  end

  context "encrypted_version4_revision4_user_pass_apples_unenc_metadata" do
    let(:filename) { pdf_spec_file("encrypted_version4_revision4_user_pass_apples_unenc_metadata") }

    context "with the user pass" do
      let(:pass) { "apples" }
      it "should correctly extract text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "should correctly extract info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate => "D:20170114125141+11'00'"
          )
        end
      end
    end
    context "with the owner pass" do
      let(:pass) { "password" }

      it "should correctly extract text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "should correctly extract info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate => "D:20170114125141+11'00'"
          )
        end
      end
    end
  end

  it "should extract inline images correctly" do
    @browser = PDF::Reader.new(pdf_spec_file("inline_image"))
    @page    = @browser.page(1)

    receiver = PDF::Reader::RegisterReceiver.new
    @page.walk(receiver)

    callbacks = receiver.series(:begin_inline_image, :begin_inline_image_data, :end_inline_image)

    # inline images should trigger 3 callbacks. The first with no args.
    expect(callbacks[0]).to eql(:name => :begin_inline_image, :args => [])

    # the second with the image header (colorspace, etc)
    expect(callbacks[1]).to eql(:name => :begin_inline_image_data, :args => [:CS, :RGB, :I, true, :W, 234, :H, 70, :BPC, 8])

    # the last with the image data
    expect(callbacks[2][:name]).to eql :end_inline_image
    image_data =  callbacks[2][:args].first

    expect(image_data).to be_a(String)
    expect(image_data.size).to  eql 49140
    expect(image_data[0,3].unpack("C*")).to   eql [255,255,255]
    expect(image_data[-3,3].unpack("C*")).to  eql [255,255,255]
  end

  it "should correctly extract text from a page that has multiple content streams" do
    filename = pdf_spec_file("content_stream_as_array")

    PDF::Reader.open(filename) do |reader|
      expect(reader.page(1).text).to include("Arkansas Declaration Relating")
    end
  end

  it "should correctly extract text from a PDF with a junk prefix" do
    filename = pdf_spec_file("junk_prefix")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to eql("This PDF contains junk before the %-PDF marker")
    end
  end

  it "should correctly extract text from a pdf that has a cmap entry that uses ligatures" do
    filename = pdf_spec_file("ligature_integration_sample")
    # there are two locations in the following pdf that have the following sequence
    # [ 85,   68,   73,    192,        70]   after cmap translation this should yield
    # [[114], [97], [102], [102, 105], [99]] or more specifically
    # [r,     a,    f,     fi,         c]
    #
    # prior to commit d37b4bf52e243dfb999fa0cda791449c50f6d16d
    # the fi would be returned as f

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      m = /raffic/.match(page.text)
      expect(m[0].to_s).to eql("raffic")
    end
  end

  it "should correctly extract text from a pdf that has a cmap entry that contains surrogate pairs" do
    filename = pdf_spec_file("surrogate_pair_integration_sample")
    # the following pdf has a sequence in it that requires 32-bit Unicode, pdf requires
    # all text to be stored in 16-bit. To acheive this surrogate-pairs are used. cmap
    # converts the surrogate-pairs back to 32-bit and ruby handles them nicely.
    # the following sequence exists in this pdf page
    # \u{1d475}\u{1d468}\u{1d47a}\u{1d46a}\u{1d468}\u{1d479} => NASCAR
    # these codepoints are in the "Math Alphanumeric Symbols (Italic) section of Unicode"
    #
    # prior to commit d37b4bf52e243dfb999fa0cda791449c50f6d16d
    # pdf-reader would return Nil instead of the correct unicode character
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      # 𝑵𝑨𝑺𝑪𝑨𝑹
      utf8_str = [0x1d475, 0x1d468, 0x1d47a, 0x1d46a, 0x1d468, 0x1d479].pack("U*")
      expect(page.text).to include(utf8_str)
    end
  end

  it "should correctly extract text from a pdf that uses a standatd font and a ligature" do
    filename = pdf_spec_file("standard_font_with_a_difference")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to eq("The following word uses a ligature: ﬁve")
    end
  end

  # TODO this spec isn't ideal as our support for extracting rotated text is quite
  #      rubbish. I've added this to ensure we don't throw an exception with
  #      rotated text. It's a start.
  it "should correctly extract text from a pdf with rotated text" do
    filename = pdf_spec_file("rotated_text")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text.split("\n").map(&:strip).slice(0,2)).to eq(["°","9"])
    end
  end

  it "should correctly extract text when a TJ operator receives an array starting with a number" do
    filename = pdf_spec_file("TJ_starts_with_a_number")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text[0,18]).to eq("This file has a TJ")
    end
  end

  it "should correctly extract text when a page is missing the MediaBox attribute" do
    filename = pdf_spec_file("mediabox_missing")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text[0,54]).to eq("This page is missing the compulsory MediaBox attribute")
    end
  end

  it "should correctly extract text from a standard font with no difference table" do
    filename = pdf_spec_file("standard_font_with_no_difference")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to eq("This page uses contains a €")
    end
  end

  it "should correctly extract zapf dingbats text" do
    filename = pdf_spec_file("zapf")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to include("✄☎✇")
    end
  end

  it "should correctly extract symbol text" do
    filename = pdf_spec_file("symbol")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to include("θρ")
    end
  end

  it "should correctly extract times text when it has a control char" do
    filename = pdf_spec_file("times-with-control-character")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to include("This text includes an ASCII control")
    end
  end

  it "should correctly extract text when the top-level Pages object has no Type" do
    filename = pdf_spec_file("pages_object_missing_type")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      expect(page.text).to include("The top level Pages object has no Type")
    end
  end

end
