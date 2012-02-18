# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::PageState do

  describe "##DEFAULT_GRAPHICS_STATE" do
    subject { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE }

    context "when walking more than one document" do
      let!(:expect) { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE.dup }
      before do
        2.times do
          page = PDF::Reader.new(pdf_spec_file("adobe_sample")).page(1)
          receiver = PDF::Reader::PageTextReceiver.new
          page.walk(receiver)
        end
      end
      it "should not mutate" do
        should eql(expect)
      end
    end
  end

end
