$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'


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
    params.each { |str| show_text(str) if str.kind_of?(String)}
  end
end


context "PDF::Reader" do

  specify "should interpret unicode strings correctly" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/cairo-unicode-short.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("Chunky Bacon")
  end

  specify "should process text from a the adobe sample file correctly" do
    receiver = PageTextReceiver.new
    PDF::Reader.file(File.dirname(__FILE__) + "/data/adobe_sample.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(1)
    receiver.content[0].should eql("This is a sample PDF file.If you can read this,you already have Adobe AcrobatReader installed on your computer.")
  end

  specify "should process text from a dutch PDF correctly" do
    receiver = PageTextReceiver.new
    str = "Dit\302\240is\302\240een\302\240pdf\302\240test\302\240van\302\240drie\302\240pagina’s.\302\240\302\240Pagina\302\2401"
    PDF::Reader.file(File.dirname(__FILE__) + "/data/dutch.pdf", receiver)

    # confirm the text appears on the correct pages
    receiver.content.size.should eql(3)
    receiver.content[0][0,str.size].should eql(str)
  end
end
