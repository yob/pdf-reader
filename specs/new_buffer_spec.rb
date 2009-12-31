$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

module BufferHelper
  def parse_string (r)
    PDF::Reader::Buffer.new(StringIO.new(r))
  end
end

context PDF::Reader::Buffer, "pop method" do
  include BufferHelper

  specify "should correctly return a simple token - 1" do
    buf = parse_string("aaa")

    buf.pop.should eql("aaa")
    buf.pop.should be_nil
  end

  specify "should correctly return a simple token - 2" do
    buf = parse_string("1.0")

    buf.pop.should eql("1.0")
    buf.pop.should be_nil
  end

  specify "should correctly return two simple tokens" do
    buf = parse_string("aaa 1.0")

    buf.pop.should eql("aaa")
    buf.pop.should eql("1.0")
    buf.pop.should be_nil
  end

  specify "should correctly return a simple token with delimiters" do
    buf = parse_string("<aaa>")

    buf.pop.should eql("<aaa>")
    buf.pop.should be_nil
  end

  specify "should correctly return two simple tokens with delimiters" do
    buf = parse_string("<aaa><bbb>")

    buf.pop.should eql("<aaa>")
    buf.pop.should eql("<bbb>")
    buf.pop.should be_nil
  end

  specify "should correctly return two name tokens" do
    buf = parse_string("/Type/Pages")

    buf.pop.should eql("/Type")
    buf.pop.should eql("/Pages")
    buf.pop.should be_nil
  end

end

context PDF::Reader::Buffer, "empty? method" do
  include BufferHelper

  specify "should correctly return false if there are remaining tokens" do
    buf = parse_string("aaa")

    buf.empty?.should be_false
  end

  specify "should correctly return true if there are no remaining tokens" do
    buf = parse_string("aaa")

    buf.empty?.should be_false
    buf.pop
    buf.empty?.should be_true
  end
end

