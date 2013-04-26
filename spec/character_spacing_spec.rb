# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader, "character spacing specs" do

  context "runs" do
    it "should have correct width on an oddly spaced sentance" do
      filename = pdf_spec_file("characterspacing")

      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)

        runs = page.default_receiver.text_runs
        runs.first.width.should be_within(1.0).of(277.45)
      end
    end

    it "should have correct width on a normally spaced" do
      filename = pdf_spec_file("characterspacing")

      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)

        runs = page.default_receiver.text_runs
        runs[2].width.should be_within(1.0).of(219.37)
      end
    end

  end

end