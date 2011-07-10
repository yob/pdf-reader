require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::BoxNesting do

  it "pass files with page boxes nested appropriately" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    rule     = Preflight::Rules::BoxNesting.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "pass files with inherited page boxes nested appropriately" do
    filename = pdf_spec_file("inherited_page_attributes")
    rule     = Preflight::Rules::BoxNesting.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should be_empty
      end
    end
  end

  it "fail files with a BleedBox smaller than MediaBox" do
    filename = pdf_spec_file("bleedbox_larger_than_mediabox")
    rule     = Preflight::Rules::BoxNesting.new

    PDF::Reader.open(filename) do |reader|
      reader.pages.each do |page|
        rule.check_page(page).should_not be_empty
      end
    end
  end

end
