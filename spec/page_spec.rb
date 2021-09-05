# typed: false
# coding: utf-8

describe PDF::Reader::Page do
  describe "#initialize" do
    it "raises InvalidPageError when an invalid page number is provided" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      expect {
        PDF::Reader::Page.new(@browser.objects, 10)
      }.to raise_error(PDF::Reader::InvalidPageError)
    end
  end

  describe "#raw_content" do
    it "returns a string from raw_content() from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.raw_content).to be_a_kind_of(String)
    end
  end

  describe "#text" do
    # only do a very basic test here. Detailed testing of text extraction is
    # done by testing the PageTextReceiver class
    it "returns the text content from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.text).to eql("Hello James")
    end

  end

  describe "#boxes" do
    let!(:page)    { browser.page(1) }
    let!(:browser) { PDF::Reader.new(pdf_spec_file("all_page_boxes_exist")) }

    it "returns a hash of all the different boxes" do
      expect(page.attributes[:ArtBox]).to_not be_empty
      expect(page.attributes[:BleedBox]).to_not be_empty
      expect(page.attributes[:CropBox]).to_not be_empty
      expect(page.attributes[:MediaBox]).to_not be_empty
      expect(page.attributes[:TrimBox]).to_not be_empty

      expect(page.boxes).to eq(
        {
          ArtBox: [0, 0, 612, 792],
          BleedBox: [0, 0, 612, 792],
          CropBox: [0, 0, 612, 792],
          MediaBox: [0, 0, 612, 792],
          TrimBox: [0, 0, 612, 792],
        }
      )
    end

    context "mediabox and cropbox are references" do
      let!(:browser) { PDF::Reader.new(pdf_spec_file("mediabox_and_cropbox_are_references")) }

      it "returns a non-reference for the dimensions of the boxes" do
        expect(page.boxes).to eq(
          {
            ArtBox: [0, 0, 612, 792],
            BleedBox: [0, 0, 612, 792],
            CropBox: [0, 0, 612, 792],
            MediaBox: [0, 0, 612, 792],
            TrimBox: [0, 0, 612, 792],
          }
        )
      end
    end
  end

  describe "#walk" do

    context "with page 1 of cairo-basic.pdf" do
      let!(:browser) { PDF::Reader.new(pdf_spec_file("cairo-basic")) }
      let!(:page)    { browser.page(1) }

      it "calls the special page= callback while walking content stream" do
        receiver = PDF::Reader::RegisterReceiver.new
        page.walk(receiver)

        callbacks = receiver.callbacks.map { |cb| cb[:name] }

        expect(callbacks.first).to eql(:page=)
      end

      it "runs callbacks while walking content stream" do
        receiver = PDF::Reader::RegisterReceiver.new
        page.walk(receiver)

        callbacks = receiver.callbacks.map { |cb| cb[:name] }

        expect(callbacks.size).to eql(16)
        expect(callbacks[0]).to eql(:page=)
        expect(callbacks[1]).to eql(:save_graphics_state)
      end

      it "runs callbacks on multiple receivers while walking content stream" do
        receiver_one = PDF::Reader::RegisterReceiver.new
        receiver_two = PDF::Reader::RegisterReceiver.new
        page.walk(receiver_one, receiver_two)

        callbacks = receiver_one.callbacks.map { |cb| cb[:name] }

        expect(callbacks.size).to eql(16)
        expect(callbacks.first).to eql(:page=)

        callbacks = receiver_two.callbacks.map { |cb| cb[:name] }

        expect(callbacks.size).to eql(16)
        expect(callbacks.first).to eql(:page=)
      end
    end
  end

  describe "#number" do

    it "returns the correct number for the current page" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.number).to eql(1)
    end

  end

  describe "#attributes" do

    it "contains attributes from the Page object" do
      @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:Resources]).to      be_a_kind_of(Hash)
      expect(attribs[:Resources].size).to eql(2)
    end

    it "contains inherited attributes" do
      @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:MediaBox]).to eql([0.0, 0.0, 595.276, 841.89])
    end

    it "allows Page to override inherited attributes" do
      @browser = PDF::Reader.new(pdf_spec_file("override_inherited_attributes"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:MediaBox]).to eql([0, 0, 200, 200])
    end

    it "does not include attributes from the Pages object that don't belong on a Page" do
      @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:Kids]).to be_nil
    end

    it "does not include attributes from the Pages object that don't belong on a Page" do
      @browser = PDF::Reader.new(pdf_spec_file("inherited_trimbox"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:TrimBox]).to be_nil
    end

    it "always includes Type => Page" do
      @browser = PDF::Reader.new(pdf_spec_file("inherited_page_attributes"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:Type]).to eql(:Page)
    end

    it 'assumes 8.5" x 11" if MediaBox is missing (matches Acrobat behaviour)' do
      @browser = PDF::Reader.new(pdf_spec_file("mediabox_missing"))
      @page    = @browser.page(1)

      attribs = @page.attributes
      expect(attribs[:MediaBox]).to eql([0,0,612,792])
    end
  end


  describe "#fonts" do

    it "returns a hash with the correct size from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.fonts).to      be_a_kind_of(Hash)
      expect(@page.fonts.size).to eql(1)
      expect(@page.fonts.keys).to eql([:"CairoFont-0-0"])
    end

    it "contains inherited resources" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.fonts).to      be_a_kind_of(Hash)
      expect(@page.fonts.size).to eql(1)
      expect(@page.fonts.keys).to eql([:"CairoFont-0-0"])
    end

  end

  describe "#color_spaces" do

    it "returns an empty hash from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.color_spaces).to      be_a_kind_of(Hash)
      expect(@page.color_spaces.size).to eql(0)
    end
  end

  describe "#graphic_states" do

    it "returns an hash with 1 entry from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.graphic_states).to      be_a_kind_of(Hash)
      expect(@page.graphic_states.size).to eql(1)
    end
  end

  describe "#orientation" do

    # this just checks that Page calls the PageOrientation class correctly. Extended specs
    # to check the different orientations are correctly detected are over in the
    # PageOrientation unit specs
    it "returns the orientation of portrait.pdf page 1 as 'portrait'" do
      @browser = PDF::Reader.new(pdf_spec_file("portrait"))
      @page    = @browser.page(1)
      expect(@page.orientation).to eql("portrait")
    end

  end

  describe "#patterns" do

    it "returns an empty hash from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.patterns).to      be_a_kind_of(Hash)
      expect(@page.patterns.size).to eql(0)
    end
  end

  describe "#procedure_sets" do

    it "returns an empty array from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.procedure_sets).to      be_a_kind_of(Array)
      expect(@page.procedure_sets.size).to eql(0)
    end
  end

  describe "#properties" do

    it "returns an empty hash from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.properties).to      be_a_kind_of(Hash)
      expect(@page.properties.size).to eql(0)
    end
  end

  describe "#shadings" do

    it "returns an empty hash from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.shadings).to      be_a_kind_of(Hash)
      expect(@page.shadings.size).to eql(0)
    end
  end

  describe "#xobjects" do

    it "returns an empty hash from cairo-basic.pdf page 1" do
      @browser = PDF::Reader.new(pdf_spec_file("cairo-basic"))
      @page    = @browser.page(1)

      expect(@page.xobjects).to      be_a_kind_of(Hash)
      expect(@page.xobjects.size).to eql(0)
    end
  end
end
