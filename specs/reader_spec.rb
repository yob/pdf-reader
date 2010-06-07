$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context PDF::Reader, "file class method" do

  before(:each) do
    @receiver = PDF::Reader::RegisterReceiver.new
    @filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
  end

  specify "should parse all aspects of a PDF file by default" do
    PDF::Reader.file(@filename, @receiver)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(1)
  end

  specify "should parse not parse metadata if requested" do
    PDF::Reader.file(@filename, @receiver, :metadata => false)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(0)
  end

  specify "should parse not parse page content if requested" do
    PDF::Reader.file(@filename, @receiver, :pages => false)
    @receiver.count(:begin_document).should eql(0)
    @receiver.count(:metadata).should eql(1)
  end

  specify "should raise an exception if an encrypted file is opened" do
    filename = File.dirname(__FILE__) + "/data/difference_table_encrypted.pdf"
    lambda {
      PDF::Reader.file(filename, @receiver)
    }.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end
end

context PDF::Reader, "string class method" do

  before(:each) do
    @receiver = PDF::Reader::RegisterReceiver.new
    filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
    if File.respond_to?(:binread)
      @data = File.binread(filename)
    else
      @data = File.open(filename, "r") { |f| f.read }
    end
  end

  specify "should parse all aspects of a PDF file by default" do
    PDF::Reader.string(@data, @receiver)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(1)
  end

  specify "should parse not parse metadata if requested" do
    PDF::Reader.string(@data, @receiver, :metadata => false)
    @receiver.count(:begin_document).should eql(1)
    @receiver.count(:metadata).should eql(0)
  end

  specify "should parse not parse page content if requested" do
    PDF::Reader.string(@data, @receiver, :pages => false)
    @receiver.count(:begin_document).should eql(0)
    @receiver.count(:metadata).should eql(1)
  end

  specify "should raise an exception if an encrypted file is opened" do
    filename = File.dirname(__FILE__) + "/data/difference_table_encrypted.pdf"
    if File.respond_to?(:binread)
      @data = File.binread(filename)
    else
      @data = File.open(filename, "r") { |f| f.read }
    end
    lambda {
      PDF::Reader.string(@data, @receiver)
    }.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end
end

context PDF::Reader, "object_file class method" do
  before(:each) do
    @filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
  end

  specify "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_file(@filename, 7, 0).should eql(515)
  end

  specify "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_file(@filename, 7).should eql(515)
  end
end

context PDF::Reader, "object_string class method" do

  before(:each) do
    filename = File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf"
    if File.respond_to?(:binread)
      @data = File.binread(filename)
    else
      @data = File.open(filename, "r") { |f| f.read }
    end
  end

  specify "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_string(@data, 7, 0).should eql(515)
  end

  specify "should extract an object from string containing a full PDF file" do
    PDF::Reader.object_string(@data, 7).should eql(515)
  end

end
