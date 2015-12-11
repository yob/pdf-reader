# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

# expose the xrefs hash inside the XRef class so we can ensure it's built correctly
class PDF::Reader::XRef
  attr_reader :xref
end

describe PDF::Reader::XRef, "initilisation" do
  context "with cairo-basic.pdf" do
    it "should load all xrefs correctly from a File" do
      filename = File.new(pdf_spec_file("cairo-basic"))
      tbl      = PDF::Reader::XRef.new(filename)
      expect(tbl.xref.keys.size).to eql(15) # 1 xref table with 16 items (ignore the first)
    end
    it "should load all xrefs correctly from a StringIO" do
      data = StringIO.new(binread(pdf_spec_file("cairo-basic")))
      tbl  = PDF::Reader::XRef.new(data)
      expect(tbl.xref.keys.size).to eql(15) # 1 xref table with 16 items (ignore the first)
    end
  end
  context "with cairo-unicode.pdf" do
    it "should load all xrefs correctly" do
      file = File.new(pdf_spec_file("cairo-unicode"))
      tbl  = PDF::Reader::XRef.new(file)
      expect(tbl.xref.keys.size).to eql(57) # 1 xref table with 58 items (ignore the first)
    end
    it "should load all xrefs correctly from a StringIO" do
      data = StringIO.new(binread(pdf_spec_file("cairo-unicode")))
      tbl  = PDF::Reader::XRef.new(data)
      expect(tbl.xref.keys.size).to eql(57) # 1 xref table with 58 items (ignore the first)
    end
  end

  context "with openoffice-2.2.pdf" do
    it "should load all xrefs correctly" do
      @file = File.new(pdf_spec_file("openoffice-2.2"))
      @tbl = PDF::Reader::XRef.new(@file)
      expect(@tbl.xref.keys.size).to eql(28) # 1 xref table with 29 items (ignore the first)
    end
  end

  context "with pdflatex.pdf" do
    it "should load all xrefs correctly" do
      @file = File.new(pdf_spec_file("pdflatex"))
      @tbl = PDF::Reader::XRef.new(@file)
      expect(@tbl.xref.keys.size).to eql(353) # 1 xref table with 360 items (but a bunch are ignored)
    end
  end

  context "with xref_subsecetions.pdf" do
    it "should load all xrefs correctly from a PDF that has multiple xref sections with subsections and xref streams" do
      @file = File.new(pdf_spec_file("xref_subsections"))
      @tbl = PDF::Reader::XRef.new(@file)
      expect(@tbl.xref.keys.size).to eql(539)
    end
  end

  context "with no_trailer.pdf" do
    it "should raise an error when attempting to locate the xref table" do
      @file = File.new(pdf_spec_file("no_trailer"))
      expect {
        PDF::Reader::XRef.new(@file)
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  context "with trailer_is_not_a_dict.pdf" do
    it "should raise an error when attempting to locate the xref table" do
      @file = File.new(pdf_spec_file("trailer_is_not_a_dict"))
      expect {
        PDF::Reader::XRef.new(@file)
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  context "with cross_ref_stream.pdf" do
    let!(:file) { File.new(pdf_spec_file("cross_ref_stream"))}
    subject     { PDF::Reader::XRef.new(file)}

    it "should correctly load all object locations" do
      expect(subject.xref.keys.size).to eql(327) # 1 xref stream with 344 items (ignore the 17 free objects)
    end

    it "should load type 1 objects references" do
      expect(subject.xref[66][0]).to eql(298219)
    end

    it "should load type 2 objects references" do
      expect(subject.xref[281][0]).to eql(PDF::Reader::Reference.new(341,0))
    end
  end

  context "with cross_ref_stream.pdf" do
    let!(:file) { File.new(pdf_spec_file("cross_ref_stream"))}
    subject     { PDF::Reader::XRef.new(file)}

    it "should raise an error when attempting to load an invalid xref stream" do
      expect do
        subject.send(:load_xref_stream, {:Subject=>"\xFE\xFF"})
      end.to raise_exception(PDF::Reader::MalformedPDFError)
    end
  end

  context "with zeroed_xref_entry.pdf" do
    let!(:file) { File.new(pdf_spec_file("zeroed_xref_entry"))}
    subject     { PDF::Reader::XRef.new(file)}

    it "should ignore non-free entries in the xref stream that point to offset 0" do
      expect(subject.size).to eql(6)
      expect(subject.xref.keys).not_to include(7)
    end
  end

  context "with junk_prefix.pdf" do
    it "should load all xrefs correctly from a File" do
      File.open(pdf_spec_file("junk_prefix")) do |file|
        tbl      = PDF::Reader::XRef.new(file)
        expect(tbl.xref.keys.size).to eql(6) # 1 xref table with 6 items (ignore the first)
      end
    end

    it "should load all xrefs with an offset to skip junk at the beginning of the file" do
      File.open(pdf_spec_file("junk_prefix")) do |file|
        tbl      = PDF::Reader::XRef.new(file)
        expect(tbl.xref[1][0]).to eq(36)
        expect(tbl.xref[2][0]).to eq(130)
      end
    end
  end
end
