require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::PrintBoxes do

  it "pass files with required page boxes" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    rule     = Preflight::Rules::PrintBoxes.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "pass files with required page boxes stored in a parent Pages object" do
    filename = pdf_spec_file("inherited_page_attributes")
    rule     = Preflight::Rules::PrintBoxes.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "fail files with no ArtBox or TrimBox" do
    filename = pdf_spec_file("no_artbox_or_trimbox")
    rule     = Preflight::Rules::PrintBoxes.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should_not be_empty
      end
    end
  end

  it "fail files with an ArtBox and TrimBox" do
    filename = pdf_spec_file("artbox_and_trimbox")
    rule     = Preflight::Rules::PrintBoxes.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should_not be_empty
      end
    end
  end

end
