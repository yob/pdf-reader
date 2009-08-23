$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context "PDF::Reader::Filter" do

  specify "should inflate a RFC1950 (zlib) deflated stream correctly"
  specify "should inflate a raw RFC1951 deflated stream correctly"
  specify "should filter a ASCII85 stream correctly" do
    filter = PDF::Reader::Filter.new(:ASCII85Decode)
    encoded_data = Ascii85::encode("Ruby")
    filter.filter(encoded_data).should eql("Ruby")
  end

  specify "should filter a ASCII85 stream missing <~ correctly" do
    filter = PDF::Reader::Filter.new(:ASCII85Decode)
    encoded_data = Ascii85::encode("Ruby")[2,100]
    filter.filter(encoded_data).should eql("Ruby")
  end

  specify "should filter a ASCIIHex stream correctly" do
    filter = PDF::Reader::Filter.new(:ASCIIHexDecode)
    encoded_data = "<52756279>"
    filter.filter(encoded_data).should eql("Ruby")
  end

  specify "should filter a ASCIIHex stream missing delimiters" do
    filter = PDF::Reader::Filter.new(:ASCIIHexDecode)
    encoded_data = "52756279"
    filter.filter(encoded_data).should eql("Ruby")
  end

  specify "should filter a ASCIIHex stream with an odd number of nibbles" do
    filter = PDF::Reader::Filter.new(:ASCIIHexDecode)
    encoded_data = "5275627"
    filter.filter(encoded_data).should eql("Rubp")
  end

end
