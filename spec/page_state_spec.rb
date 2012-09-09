# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::PageState do
  let!(:page)   { mock(:cache => {},
                        :objects => {},
                        :fonts => {},
                        :xobjects => {},
                        :color_spaces => {})}

  describe "#DEFAULT_GRAPHICS_STATE" do
    subject { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE }

    context "when walking more than one page" do
      let!(:expect) { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE.dup }

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

  describe "#save_graphics_state" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should increase the stack depth by one" do
        lambda {
          state.save_graphics_state
        }.should change(state, :stack_depth).from(1).to(2)
      end
    end
  end

  describe "#restore_graphics_state" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should reduce the stack depth by one" do
        state.save_graphics_state

        lambda {
          state.restore_graphics_state
        }.should change(state, :stack_depth).from(2).to(1)
      end
    end
  end

  describe "#concatenate_matrix" do
    let!(:state)  {PDF::Reader::PageState.new(page) }

    context "when changing value a" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(2, 0,
                                 0, 1,
                                 0, 0)
        state.clone_state[:ctm].should == [2, 0, 0,
                                           0, 1, 0,
                                           0, 0, 1]
      end
    end

    context "when changing value b" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 2,
                                 0, 1,
                                 0, 0)
        state.clone_state[:ctm].should == [1, 2, 0,
                                           0, 1, 0,
                                           0, 0, 1]
      end
    end

    context "when changing value c" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 2, 1,
                                 0, 0)
        state.clone_state[:ctm].should == [1, 0, 0,
                                           2, 1, 0,
                                           0, 0, 1]
      end
    end

    context "when changing value d" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 2,
                                 0, 0)
        state.clone_state[:ctm].should == [1, 0, 0,
                                           0, 2, 0,
                                           0, 0, 1]
      end
    end

    context "when changing value e" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 2, 0)
        state.clone_state[:ctm].should == [1, 0, 0,
                                           0, 1, 0,
                                           2, 0, 1]
      end
    end

    context "when changing value f" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 0, 2)
        state.clone_state[:ctm].should == [1, 0, 0,
                                           0, 1, 0,
                                           0, 2, 1]
      end
    end
  end

  describe "#begin_text_object" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should set the text_matrix to the identity matrix" do
        state.begin_text_object
        state.instance_variable_get(:@text_matrix).should == [1,0,0,
                                                              0,1,0,
                                                              0,0,1]

      end
    end
  end

end
