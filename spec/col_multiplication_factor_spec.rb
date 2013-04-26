# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader, "column multiplation factor specs" do

  context "when set at 1.05" do
    it "does not render properly" do
      filename = pdf_spec_file("col_multiplication_factor")

      PDF::Reader.open(filename) do |reader|
        reader.page(1).text.should =~ /Address correspondence to Albert I. King, Biomedical Engineering confidenc/
      end
    end
  end
  
  context "when set at 1.15" do
    it "does render properly" do
      filename = pdf_spec_file("col_multiplication_factor")

      PDF::Reader.open(filename, :page_layout => {:col_multiplication_factor => 1.15}) do |reader|
        reader.page(1).text.should =~ /Address correspondence to Albert I. King, Biomedical Engineering\s+the confidenc/
      end
    end
  end
end