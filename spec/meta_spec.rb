# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

# These specs are a kind of "integration spec". They're not unit testing small pieces
# of code, it's just parsing a range of PDF files and ensuring the result is
# consistent. An extra check to make sure parsing these files will continue
# to work for our users.
#
# Where possible, specs that unit test correctly should be written in addition to
# these

describe PDF::Reader, "meta specs" do

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
      page.text.should eql("V\ne\nr\nt\ni\nc\na\nl\n \nT\ne\nx\nt")
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
      page.text.should include("Dit\302\240is\302\240een\302\240pdf\302\240test\302\240van\302\240drie\302\240pagina’s.")
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
      page.text.should match(/\ATaxInvoice/)
    end
  end

  it "should correctly process a PDF with a content stream that is missing an operator (has hanging params)" do
    filename = pdf_spec_file("content_stream_missing_final_operator")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text.should match(/\ALocatrix/)
      reader.page(2).text.should match(/\AUbuntu/)
    end
  end

  it "should correctly process a PDF with a string containing a high byte (D1) under MacRomanEncoding" do
    # this spec is to detect an hard lock issue some people were encountering on some OSX
    # systems. Real pain to debug.
    filename = pdf_spec_file("hard_lock_under_osx")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text[0,1].should eql("’")
    end
  end

  it "should not hang when processing a PDF that has a content stream with a broken string" do
    filename = pdf_spec_file("broken_string")

    # this file used to get us into a hard, endless loop. Make sure that doesn't still happen
    Timeout::timeout(3) do
      lambda {
        reader = PDF::Reader.new(filename)
        reader.page(1).text
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

  it "should correctly process a PDF that uses an ASCII85Decode filter" do
    filename = pdf_spec_file("ascii85_filter")

    PDF::Reader.open(filename) do |reader|
      reader.page(1).text[0,11].should eql("Et Iunia se")
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

  it "should correctly extract text from an encrypted PDF with a user password" do
    filename = pdf_spec_file("encrypted_with_user_pass_apples")

    PDF::Reader.open(filename, :userpass => "apples") do |reader|
      reader.page(1).text.should eql("This sample file is encrypted with a user password")
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
end
