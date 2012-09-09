# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::PageState do

  describe "##DEFAULT_GRAPHICS_STATE" do
    subject { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE }

    context "when walking more than one page" do
      let!(:expect) { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE.dup }
      let!(:page)   { mock(:cache => {}, :objects => {}, :fonts => {}, :xobjects => {}, :color_spaces => {})}

      before do
        2.times do
          state = PDF::Reader::PageState.new(page)
          state.save_graphics_state
          state.concatenate_matrix(1,2,3,4,5,6)
        end
      end

      it "should not mutate" do
        should eql(expect)
      end
    end
  end

end
