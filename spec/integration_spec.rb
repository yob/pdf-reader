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
      page.text.should eql("Chunky Bacon")
    end
  end

  it "should interpret Identity-V encoded strings correctly" do
    filename = pdf_spec_file("vertical-text-in-identity-v")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.split.map(&:strip).should eql(%w{V e r t i c a l T e x t})
    end
  end

  it "should process text from a the adobe sample file correctly" do
    filename = pdf_spec_file("adobe_sample")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should include("This is a sample PDF file")
      page.text.should include("If you can read this, you already have Adobe Acrobat")
    end
  end

  it "should process text from a dutch PDF correctly" do
    filename = pdf_spec_file("dutch")

    PDF::Reader.open(filename) do |reader|
      reader.pages.size.should eql(3)

      page = reader.page(1)
      page.text.should include("Dit\302\240is\302\240een\302\240pdf\302\240test\302\240van\302\240drie\302\240pagina")
      page.text.should include("’s")
      page.text.should include("Pagina\302\2401")
    end
  end

  it "should process text from a PDF with a difference table correctly" do
    filename = pdf_spec_file("difference_table")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should eql("Goiás")
    end
  end

  it "should process text from a PDF with a content stream that has trailing whitespace" do
    filename = pdf_spec_file("content_stream_trailing_whitespace")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should match(/Tax\s+Invoice/)
    end
  end

  it "should correctly process a PDF with a content stream that is missing an operator (has hanging params)" do
    filename = pdf_spec_file("content_stream_missing_final_operator")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should match(/Locatrix/)
      reader.page(2).text.should match(/Ubuntu/)
    end
  end

  it "should correctly process a PDF with a string containing a high byte (D1) under MacRomanEncoding" do
    # this spec is to detect an hard lock issue some people were encountering on some OSX
    # systems. Real pain to debug.
    filename = pdf_spec_file("hard_lock_under_osx")

    PDF::Reader.open(filename) do |reader|
      if RUBY_VERSION >= "1.9"
        reader.page(1).text[0,1].should eql("’")
      else
        reader.page(1).text[0,3].should eql("’")
      end
    end
  end

  it "should not hang when processing a PDF that has a content stream with a broken string" do
    filename = pdf_spec_file("broken_string")

    # this file used to get us into a hard, endless loop. Make sure that doesn't still happen
    Timeout::timeout(3) do
      lambda {
        reader = PDF::Reader.new(filename)
        reader.info
      }.should raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  it "should correctly process a PDF with a stream that has its length specified as an indirect reference" do
    filename = pdf_spec_file("content_stream_with_length_as_ref")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("Hello World")
    end
  end

  # PDF::Reader::XRef#object was saving an incorrect position when seeking. We
  # were saving the current pos of the underlying IO stream, then seeking back
  # to it. This was fine, except when there was still content in the buffer.
  it "should correctly process a PDF with a stream that has its length specified as an indirect reference and uses windows line breaks" do
    filename = pdf_spec_file("content_stream_with_length_as_ref_and_windows_breaks")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("Hello World")
    end
  end

  it "should raise an exception if a content stream refers to a non-existant font" do
    filename = pdf_spec_file("content_stream_refers_to_invalid_font")

    lambda {
      reader = PDF::Reader.new(filename)
      reader.page(1).text
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end

  it "should raise an exception if the file is empty" do
    lambda {
      PDF::Reader.new(StringIO.new(""))
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end

  it "should correctly process a PDF that uses an ASCII85Decode filter" do
    filename = pdf_spec_file("ascii85_filter")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should match(/Et Iunia se/)
    end
  end

  it "should correctly process a PDF that has an inline image in a content stream with no line breaks" do
    filename = pdf_spec_file("inline_image_single_line_content_stream")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.strip[0,7].should eql("WORKING")
    end
  end

  it "should correctly process a PDF that uses Form XObjects to repeat content" do
    filename = pdf_spec_file("form_xobject")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("James Healy")
      reader.page(2).text.should eql("James Healy")
    end
  end

  it "should correctly process a PDF that uses Form XObjects to repeat content" do
    filename = pdf_spec_file("form_xobject_more")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should include("Some regular content")
      reader.page(1).text.should include("James Healy")
      reader.page(2).text.should include("€10")
      reader.page(2).text.should include("James Healy")
    end
  end

  it "should correctly process a PDF that uses indirect Form XObjects to repeat content" do
    filename = pdf_spec_file("indirect_xobject")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should_not be_nil
    end
  end

  it "should correctly process a PDF that uses multiple content streams for a single page" do
    filename = pdf_spec_file("split_params_and_operator")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should include("My name is")
      reader.page(1).text.should include("James Healy")
    end
  end

  it "should correctly process a PDF that has a single space after the EOF marker" do
    filename = pdf_spec_file("space_after_eof")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("Hello World")
    end
  end

  it "should correctly extract text from a PDF that was generated in open office 3" do
    filename = pdf_spec_file("oo3")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should include("test")
    end
  end

  it "should correctly extract text from a PDF has newlines at the start of a content stream" do
    filename = pdf_spec_file("content_stream_begins_with_newline")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("This file has a content stream that begins with \\n\\n")
    end
  end

  it "should correctly extract text from an encrypted PDF with no user password" do
    filename = pdf_spec_file("encrypted_no_user_pass")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("This sample file is encrypted with no user password")
    end
  end

  it "should correctly extract text from an encrypted PDF with no user password and revision 1" do
    filename = pdf_spec_file("encrypted_with_no_user_pass_and_revision_one")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should eql("WOOOOO DOCUMENT!")
    end
  end

  it "should correctly extract text from an encrypted PDF with a user password" do
    filename = pdf_spec_file("encrypted_with_user_pass_apples")

    PDF::Reader.open(filename, :password => "apples") do |reader|
      reader.page(1).text.should match(/^This sample file is encrypted with a user password.$/m)
      reader.page(1).text.should match(/^User password: apples$/m)
      reader.page(1).text.should match(/^Owner password: password$/m)
    end
  end

  it "should correctly extract text from an encrypted PDF with an owner password" do
    filename = pdf_spec_file("encrypted_with_user_pass_apples")

    PDF::Reader.open(filename, :password => "password") do |reader|
      reader.page(1).text.should match(/^This sample file is encrypted with a user password.$/)
      reader.page(1).text.should match(/^User password: apples$/m)
      reader.page(1).text.should match(/^Owner password: password$/m)
    end
  end

  it "should raise an exception from an encrypted PDF that requires a user password and none is provided" do
    filename = pdf_spec_file("encrypted_with_user_pass_apples")

    lambda {
      PDF::Reader.open(filename) do |reader|
        reader.page(1).text
      end
    }.should raise_error(PDF::Reader::EncryptedPDFError)
  end

  it "should extract inline images correctly" do
    @browser = PDF::Reader.new(pdf_spec_file("inline_image"))
    @page    = @browser.page(1)

    receiver = PDF::Reader::RegisterReceiver.new
    @page.walk(receiver)

    callbacks = receiver.series(:begin_inline_image, :begin_inline_image_data, :end_inline_image)

    # inline images should trigger 3 callbacks. The first with no args.
    callbacks[0].should eql(:name => :begin_inline_image, :args => [])

    # the second with the image header (colorspace, etc)
    callbacks[1].should eql(:name => :begin_inline_image_data, :args => [:CS, :RGB, :I, true, :W, 234, :H, 70, :BPC, 8])

    # the last with the image data
    callbacks[2][:name].should eql :end_inline_image
    image_data =  callbacks[2][:args].first

    image_data.should be_a(String)
    image_data.size.should  eql 49140
    image_data[0,3].unpack("C*").should   eql [255,255,255]
    image_data[-3,3].unpack("C*").should  eql [255,255,255]
  end

  it "should correctly extract text from a page that has multiple content streams" do
    filename = pdf_spec_file("content_stream_as_array")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should include("Arkansas Declaration Relating")
    end
  end

  it "should correctly extract text from a PDF with a junk prefix" do
    filename = pdf_spec_file("junk_prefix")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should eql("This PDF contains junk before the %-PDF marker")
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
      m[0].to_s.should eql("raffic")
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
      page.text.should include(utf8_str)
    end
  end

  it "should correctly extract text from a pdf that uses a standatd font and a ligature" do
    filename = pdf_spec_file("standard_font_with_a_difference")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should == "The following word uses a ligature: ﬁve"
    end
  end

  # TODO this spec isn't ideal as our support for extracting rotated text is quite
  #      rubbish. I've added this to ensure we don't throw an exception with
  #      rotated text. It's a start.
  it "should correctly extract text from a pdf with rotated text" do
    filename = pdf_spec_file("rotated_text")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.split("\n").map(&:strip).slice(0,2).should == ["°","9"]
    end
  end

  it "should correctly extract text when a TJ operator receives an array starting with a number" do
    filename = pdf_spec_file("TJ_starts_with_a_number")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text[0,18].should == "This file has a TJ"
    end
  end

  it "should correctly extract text when a page is missing the MediaBox attribute" do
    filename = pdf_spec_file("mediabox_missing")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text[0,54].should == "This page is missing the compulsory MediaBox attribute"
    end
  end

  it "should correctly extract text from a standard font with no difference table" do
    filename = pdf_spec_file("standard_font_with_no_difference")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should == "This page uses contains a €"
    end
  end

  it "should correctly extract zapf dingbats text" do
    filename = pdf_spec_file("zapf")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should include("✄☎✇")
    end
  end

  it "should correctly extract symbol text" do
    filename = pdf_spec_file("symbol")
    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      page.text.should include("θρ")
    end
  end
end
