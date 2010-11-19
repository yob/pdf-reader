# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

# These specs are a kind of "meta spec". They're not unit testing small pieces
# of code, it's just parsing a range of PDF files and ensuring the result is
# consistant. An extra check to make sure parsing these files will continue
# to work for our users. 
#
# Where possible, specs that unit test correctly should be written in prefernce to
# these

class PageTextReceiver
  attr_accessor :content

  def initialize
    @content = []
  end

  # Called when page parsing starts
  def begin_page(arg = nil)
    @content << ""
  end

  def show_text(string, *params)
    @content.last << string.strip
  end

  # there's a few text callbacks, so make sure we process them all
  alias :super_show_text :show_text
  alias :move_to_next_line_and_show_text :show_text
  alias :set_spacing_next_line_show_text :show_text

  def show_text_with_positioning(*params)
    params = params.first
    params ||= []
    params.each { |str| show_text(str) if str.kind_of?(String)}
  end
end


describe PDF::Reader, "meta specs" do

  it "should interpret unicode strings correctly" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("Chunky Bacon")
  end

  it "should process text from a the adobe sample file correctly" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/adobe_sample.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("This is a sample PDF file.If you can read this,you already have Adobe AcrobatReader installed on your computer.")
  end

  it "should process text from a dutch PDF correctly" do
    receiver = PageTextReceiver.new
    str1 = "Dit\302\240is\302\240een\302\240pdf\302\240test\302\240van\302\240drie\302\240pagina’s."
    str2 = "Pagina\302\2401"
    PDF::Reader.file(File.dirname(__FILE__) + "/data/dutch.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(3)
    receiver.content[0].include?(str1).should be_true
    receiver.content[0].include?(str2).should be_true
  end

  it "should process text from a PDF with a difference table correctly" do
    receiver = PageTextReceiver.new
    str = "Goiás"
    PDF::Reader.file(File.dirname(__FILE__) + "/data/difference_table.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql(str)
  end

  it "should process text from a PDF with a content stream that has trailing whitespace" do
    receiver = PageTextReceiver.new
    str = "TaxInvoice"
    PDF::Reader.file(File.dirname(__FILE__) + "/data/content_stream_trailing_whitespace.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].slice(0,10).should eql(str)
  end

  it "should correctly process a PDF with a content stream that is missing an operator (has hanging params)" do
    receiver = PageTextReceiver.new
    str1 = "Locatrix"
    str2 = "Ubuntu"
    PDF::Reader.file(File.dirname(__FILE__) + "/data/content_stream_missing_final_operator.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(2)
    receiver.content[0].slice(0,8).should eql(str1)
    receiver.content[1].slice(0,6).should eql(str2)
  end

  it "should correctly process a PDF with a string containing a high byte (D1) under MacRomanEncoding" do
    # this spec is to detect an hard lock issue some people were encountering on some OSX
    # systems. Real pain to debug.
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/hard_lock_under_osx.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("’")
  end

  it "should not hang when processing a PDF that has a content stream with a broken string" do
    receiver = PageTextReceiver.new

    # this file used to get us into a hard, endless loop. Make sure that doesn't still happen
    Timeout::timeout(3) do
      lambda {
        PDF::Reader.file(File.dirname(__FILE__) + "/data/broken_string.pdf", receiver)
      }.should raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  it "should correctly process a PDF with a stream that has its length specified as an indirect reference" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/content_stream_with_length_as_ref.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("HelloWorld")
  end

  # PDF::Reader::XRef#object was saving an incorrect position when seeking. We
  # were saving the current pos of the underlying IO stream, then seeking back
  # to it. This was fine, except when there was still content in the buffer.
  it "should correctly process a PDF with a stream that has its length specified as an indirect reference and uses windows line breaks" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/content_stream_with_length_as_ref_and_windows_breaks.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("HelloWorld")
  end

  it "should raise an exception if a content stream refers to a non-existant font" do
    receiver = PageTextReceiver.new
    lambda {
      PDF::Reader.file(File.dirname(__FILE__) + "/data/content_stream_refers_to_invalid_font.pdf", receiver)
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end

  it "should correctly process a PDF that uses an ASCII85Decode filter" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/ascii85_filter.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0][0,19].should eql("Et Iunia sexagesimo")
  end

  it "should correctly process a PDF that has an inline image in a content stream with no line breaks" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/inline_image_single_line_content_stream.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0][0,7].should eql("WORKING")
  end

  it "should correctly process a PDF that uses Form XObjects to repeat content" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/form_xobject.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(2)
    receiver.content[0].should eql("James Healy")
    receiver.content[1].should eql("James Healy")
  end

  it "should correctly process a PDF that uses Form XObjects to repeat content" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/form_xobject_more.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(2)

    # regular content should be visible
    receiver.content[0].include?("Some regular content").should be_true
    receiver.content[1].include?("€10").should be_true

    # form xobject content should be visible
    receiver.content[0].include?("James Healy").should be_true
    receiver.content[1].include?("James Healy").should be_true
  end

  it "should correctly process a PDF that uses indirect Form XObjects to repeat content" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/indirect_xobject.pdf", receiver)

    # confirm there was a single page of text
    receiver.content.size.should eql(1)
  end

  it "should correctly process a PDF that uses multiple content streams for a single page" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/split_params_and_operator.pdf", receiver)

    # confirm there was a single page of text
    receiver.content.size.should eql(1)
    receiver.content[0].include?("My name is").should be_true
    receiver.content[0].include?("James Healy").should be_true
  end

  it "should correctly process a PDF that has a single space after the EOF marker" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/space_after_eof.pdf", receiver)

    # confirm there was a single page of text
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("HelloWorld")
  end

  it "should correctly extract text from a PDF that was generated in open office 3" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/oo3.pdf", receiver)

    # confirm there was a single page of text
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("test")
  end
end
