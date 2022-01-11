# typed: false
# coding: utf-8

# A set of integration specs that assert we raise expected errors when trying to parse PDFs that
# are invalid. Usually they have some form of corruption that we're unable to compensate for

describe PDF::Reader, "integration specs with invalid PDF files" do

  context "Empty file" do
    it "raises an exception" do
      expect {
        PDF::Reader.new(StringIO.new(""))
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  context "PDF has a content stream refers to a non-existant font" do
    let(:filename) { pdf_spec_file("content_stream_refers_to_invalid_font") }

    it "raises an exception" do
      expect {
        reader = PDF::Reader.new(filename)
        reader.page(1).text
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  context "Malformed PDF" do
    let(:filename) { pdf_spec_file("trailer_root_is_not_a_dict") }

    it "raises an exception if trailer Root is not a dict" do
      PDF::Reader.open(filename) do |reader|
        expect { reader.page(1) }.to raise_error(PDF::Reader::MalformedPDFError)
      end
    end
  end

  context "PDF with missing page data" do
    let(:filename) { pdf_spec_file("invalid_pages") }

    it "raises a MalformedPDFError when an InvalidPageError is raised internally" do
      PDF::Reader.open(filename) do |reader|
        expect { reader.pages }.to raise_error(PDF::Reader::MalformedPDFError)
      end
    end
  end

  context "PDF that has a content stream with a broken string" do
    let(:filename) { pdf_spec_file("broken_string") }

    # this file used to get us into a hard, endless loop. Make sure that doesn't still happen
    it "doesn't hang when extracting doc info" do
      Timeout::timeout(3) do
        expect {
          reader = PDF::Reader.new(filename)
          reader.info
        }.to raise_error(PDF::Reader::MalformedPDFError)
      end
    end
  end

end
