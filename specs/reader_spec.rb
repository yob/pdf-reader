$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context "The PDF::Reader class" do

  specify "should parse all aspects of a PDF file by default" do
    receiver = PDF::Reader::RegisterReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.count(:begin_document).should eql(1)
    receiver.count(:metadata).should eql(1)
  end

  specify "should parse not parse metadata if requested" do
    receiver = PDF::Reader::RegisterReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf", receiver, :metadata => false)

    # confirm the text appears on the correct pages
    receiver.count(:begin_document).should eql(1)
    receiver.count(:metadata).should eql(0)
  end

  specify "should parse not parse page content if requested" do
    receiver = PDF::Reader::RegisterReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf", receiver, :pages => false)

    # confirm the text appears on the correct pages
    receiver.count(:begin_document).should eql(0)
    receiver.count(:metadata).should eql(1)
  end
end
