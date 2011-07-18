require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::OnlyEmbeddedFonts do

  it "pass files with a subsetted TTF font" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    rule     = Preflight::Rules::OnlyEmbeddedFonts.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "pass files with a complete TTF font" do
    filename = pdf_spec_file("pdfx-1a-no-subsetting")
    rule     = Preflight::Rules::OnlyEmbeddedFonts.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "pass files with a subsetted Type1 font as a descendant of a Type0 font"

  it "pass files with a subsetted TTF font as a descendant of a Type0 font" do
    filename = pdf_spec_file("pdfa-1a")
    rule     = Preflight::Rules::OnlyEmbeddedFonts.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "fail files with a adobe 'standard 14' font" do
    filename = pdf_spec_file("standard_14_font")
    rule     = Preflight::Rules::OnlyEmbeddedFonts.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should_not be_empty
      end
    end
  end

  it "pass files with a non-embedded base-14 font in an AcroForm that has no fields" do
    filename = pdf_spec_file("acroform")
    rule     = Preflight::Rules::OnlyEmbeddedFonts.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "pass files with a Type3 font"

end
