$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context "PDF::Reader::Filter" do

  specify "should inflate a RFC1950 (zlib) deflated stream correctly"
  specify "should inflate a raw RFC1951 deflated stream correctly"

end
