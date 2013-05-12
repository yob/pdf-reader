# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Page, "raw_content()" do
  it "should return a string from raw_content() from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.raw_content.should be_a_kind_of(String)
  end
end

describe PDF::Reader::Page, "text()" do
  # only do a very basc test here. Detailed testing of text extraction is
  # done by testing the PageTextReceiver class
  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.text.should eql("Hello James")
  end

end

describe PDF::Reader::Page, "walk()" do

  context "with page 1 of cairo-basic.pdf" do
    let!(:browser) { PDF::Reader.new(pdf_spec_file("cairo-basic")) }
    let!(:page)    { browser.page(1) }

    it "should call the special page= callback while walking content stream" do
      receiver = PDF::Reader::RegisterReceiver.new
      page.walk(receiver)

      callbacks = receiver.callbacks.map { |cb| cb[:name] }

      callbacks.first.should eql(:page=)
    end

    it "should run callbacks while walking content stream" do
      receiver = PDF::Reader::RegisterReceiver.new
      page.walk(receiver)

      callbacks = receiver.callbacks.map { |cb| cb[:name] }

      callbacks.size.should eql(16)
      callbacks[0].should eql(:page=)
      callbacks[1].should eql(:save_graphics_state)
    end

    it "should run callbacks on multiple receivers while walking content stream" do
      receiver_one = PDF::Reader::RegisterReceiver.new
      receiver_two = PDF::Reader::RegisterReceiver.new
      page.walk(receiver_one, receiver_two)

      callbacks = receiver_one.callbacks.map { |cb| cb[:name] }

      callbacks.size.should eql(16)
      callbacks.first.should eql(:page=)

      callbacks = receiver_two.callbacks.map { |cb| cb[:name] }

      callbacks.size.should eql(16)
      callbacks.first.should eql(:page=)
    end
  end
end

describe PDF::Reader::Page, "number()" do

  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.number.should eql(1)
  end

end

describe PDF::Reader::Page, "number()" do

  it "should return the text content from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.number.should eql(1)
  end

end

describe PDF::Reader::Page, "attributes()" do

  it "should contain attributes from the Page object" do
    @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:Resources].should      be_a_kind_of(Hash)
    attribs[:Resources].size.should eql(2)
  end

  it "should contain inherited attributes" do
    @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:MediaBox].should eql([0.0, 0.0, 595.276, 841.89])
  end

  it "should allow Page to override inherited attributes" do
    @browser = PDF::Reader.new(pdf_spec_file("override_inherited_attributes"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:MediaBox].should eql([0, 0, 200, 200])
  end

  it "should not include attributes from the Pages object that don't belong on a Page" do
    @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:Kids].should be_nil
  end

  it "should not include attributes from the Pages object that don't belong on a Page" do
    @browser = PDF::Reader.new(pdf_spec_file("inherited_trimbox"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:TrimBox].should be_nil
  end

  it "should always include Type => Page" do
    @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:Type].should eql(:Page)
  end

  it 'should assume 8.5" x 11" if MediaBox is missing (matches Acrobat behaviour)' do
    @browser = PDF::Reader.new(pdf_spec_file("mediabox_missing"))
    @page    = @browser.page(1)

    attribs = @page.attributes
    attribs[:MediaBox].should eql([0,0,612,792])
  end
end


describe PDF::Reader::Page, "fonts()" do

  it "should return a hash with the correct size from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.fonts.should      be_a_kind_of(Hash)
    @page.fonts.size.should eql(1)
    @page.fonts.keys.should eql([:"CairoFont-0-0"])
  end

  it "should contain inherited resources" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.fonts.should      be_a_kind_of(Hash)
    @page.fonts.size.should eql(1)
    @page.fonts.keys.should eql([:"CairoFont-0-0"])
  end

end

describe PDF::Reader::Page, "color_spaces()" do

  it "should return an empty hash from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.color_spaces.should      be_a_kind_of(Hash)
    @page.color_spaces.size.should eql(0)
  end
end

describe PDF::Reader::Page, "graphic_states()" do

  it "should return an hash with 1 entry from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.graphic_states.should      be_a_kind_of(Hash)
    @page.graphic_states.size.should eql(1)
  end
end

describe PDF::Reader::Page, "orientation()" do

  it "should return the orientation of portrait.pdf page 1 as 'portrait'" do
    @browser = PDF::Reader.new(pdf_spec_file("portrait"))
    @page    = @browser.page(1)
    @page.orientation.should eql("portrait")
  end

end

describe PDF::Reader::Page, "patterns()" do

  it "should return an empty hash from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.patterns.should      be_a_kind_of(Hash)
    @page.patterns.size.should eql(0)
  end
end

describe PDF::Reader::Page, "procedure_sets()" do

  it "should return an empty array from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.procedure_sets.should      be_a_kind_of(Array)
    @page.procedure_sets.size.should eql(0)
  end
end

describe PDF::Reader::Page, "properties()" do

  it "should return an empty hash from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.properties.should      be_a_kind_of(Hash)
    @page.properties.size.should eql(0)
  end
end

describe PDF::Reader::Page, "shadings()" do

  it "should return an empty hash from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.shadings.should      be_a_kind_of(Hash)
    @page.shadings.size.should eql(0)
  end
end

describe PDF::Reader::Page, "xobjects()" do

  it "should return an empty hash from cairo-basic.pdf page 1" do
    @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
    @page    = @browser.page(1)

    @page.xobjects.should      be_a_kind_of(Hash)
    @page.xobjects.size.should eql(0)
  end
end
