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

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [0, 0]
        state.ctm_transform(0,1).should == [0, 1]
        state.ctm_transform(1,0).should == [2, 0]
        state.ctm_transform(1,1).should == [2, 1]
      end
    end

    context "when changing value b" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 2,
                                 0, 1,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [0, 0]
        state.ctm_transform(0,1).should == [0, 1]
        state.ctm_transform(1,0).should == [1, 2]
        state.ctm_transform(1,1).should == [1, 3]
      end
    end

    context "when changing value c" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 2, 1,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [0, 0]
        state.ctm_transform(0,1).should == [2, 1]
        state.ctm_transform(1,0).should == [1, 0]
        state.ctm_transform(1,1).should == [3, 1]
      end
    end

    context "when changing value d" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 2,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [0, 0]
        state.ctm_transform(0,1).should == [0, 2]
        state.ctm_transform(1,0).should == [1, 0]
        state.ctm_transform(1,1).should == [1, 2]
      end
    end

    context "when changing value e" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 2, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [2, 0]
        state.ctm_transform(0,1).should == [2, 1]
        state.ctm_transform(1,0).should == [3, 0]
        state.ctm_transform(1,1).should == [3, 1]
      end
    end

    context "when changing value f" do
      it "should correctly multiply the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 0, 2)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [0, 2]
        state.ctm_transform(0,1).should == [0, 3]
        state.ctm_transform(1,0).should == [1, 2]
        state.ctm_transform(1,1).should == [1, 3]
      end
    end

    context "when applying a rotation followed by a translation" do
      it "should correctly multiply the matrixes using pre-multiplication" do
        angle = 90 * Math::PI / 180 # 90 degrees
        state.concatenate_matrix( Math.cos(angle), Math.sin(angle),
                                 -Math.sin(angle), Math.cos(angle),
                                  0, 0)
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 10, 10)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.ctm_transform(0,0).should == [-10,10]
        state.ctm_transform(0,1).should == [-11,10]
        state.ctm_transform(1,0).should == [-10,11]
        state.ctm_transform(1,1).should == [-11,11]
      end
    end
  end

  describe "#begin_text_object" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should initialze the text_matrix to ensure text is positioned at 0,0" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)

        state.trm_transform(0,0).should == [0,0]
        state.trm_transform(0,1).should == [0, 12]
        state.trm_transform(1,0).should == [12, 0]
        state.trm_transform(1,1).should == [12, 12]
      end
    end
  end

  describe "#move_text_position" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position(5, 10)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [5,10]
        state.trm_transform(0,1).should == [5, 22]
        state.trm_transform(1,0).should == [17, 10]
        state.trm_transform(1,1).should == [17, 22]
      end
    end
  end

  describe "#move_text_position_and_set_leading" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position_and_set_leading(5, 10)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [5, 10]
        state.trm_transform(0,1).should == [5, 22]
        state.trm_transform(1,0).should == [17, 10]
        state.trm_transform(1,1).should == [17, 22]
      end

      it "should correctly alter the text leading" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position_and_set_leading(5, 10)

        state.clone_state[:text_leading].should == -10
      end
    end
  end

  describe "#set_text_matrix_and_text_line_matrix" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_matrix_and_text_line_matrix(1, 2, 3, 4, 5, 6)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [5, 6]
        state.trm_transform(0,1).should == [41, 54]
        state.trm_transform(1,0).should == [17, 30]
        state.trm_transform(1,1).should == [53.0, 78.0]
      end
    end
  end

  describe "#move_to_start_of_next_line" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_leading(15)
        state.move_to_start_of_next_line

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [0, -15]
        state.trm_transform(0,1).should == [0, -3]
        state.trm_transform(1,0).should == [12, -15]
        state.trm_transform(1,1).should == [12, -3]
      end
    end
  end

  describe "#move_to_next_line_and_show_text" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_leading(15)
        state.move_to_next_line_and_show_text("Foo")

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [0, -15]
        state.trm_transform(0,1).should == [0, -3]
        state.trm_transform(1,0).should == [12, -15]
        state.trm_transform(1,1).should == [12, -3]
      end
    end
  end

  describe "#move_to_next_line_and_show_text" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_leading(15)
        state.move_to_next_line_and_show_text("Foo")

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [0, -15]
        state.trm_transform(0,1).should == [0, -3]
        state.trm_transform(1,0).should == [12, -15]
        state.trm_transform(1,1).should == [12, -3]
      end
    end
  end

  describe "#set_spacing_next_line_show_text" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "should set word spacing" do
        state.begin_text_object
        state.set_spacing_next_line_show_text(10, 20, "test")
        state.clone_state[:word_spacing].should == 10
      end

      it "should set character spacing" do
        state.begin_text_object
        state.set_spacing_next_line_show_text(10, 20, "test")
        state.clone_state[:char_spacing].should == 20
      end

      it "should correctly alter the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_spacing_next_line_show_text(10, 20, "test")

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [0, 0]
        state.trm_transform(0,1).should == [0, 12]
        state.trm_transform(1,0).should == [12, 0]
        state.trm_transform(1,1).should == [12, 12]
      end
    end
  end

  describe "#process_glyph_displacement" do
    context "when the current state places 12pt text at (40, 700)" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      before do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position(40, 700)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        state.trm_transform(0,0).should == [40, 700]
        state.trm_transform(0,1).should == [40, 712]
        state.trm_transform(1,0).should == [52, 700]
        state.trm_transform(1,1).should == [52, 712]
      end

      context "2pt glyph width" do
        context "no character spacing" do
          context "no word spacing" do
            context "no kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  state.trm_transform(0,0).should == [64, 700]
                  state.trm_transform(0,1).should == [64, 712]
                  state.trm_transform(1,0).should == [76, 700]
                  state.trm_transform(1,1).should == [76, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  state.trm_transform(0,0).should == [64, 700]
                  state.trm_transform(0,1).should == [64, 712]
                  state.trm_transform(1,0).should == [76, 700]
                  state.trm_transform(1,1).should == [76, 712]
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  state.trm_transform(0,0).should == [63.976, 700]
                  state.trm_transform(0,1).should == [63.976, 712]
                  state.trm_transform(1,0).should == [75.976, 700]
                  state.trm_transform(1,1).should == [75.976, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  state.trm_transform(0,0).should == [63.976, 700]
                  state.trm_transform(0,1).should == [63.976, 712]
                  state.trm_transform(1,0).should == [75.976, 700]
                  state.trm_transform(1,1).should == [75.976, 712]
                end
              end
            end
          end
          context "with word spacing" do
            before do
              state.set_word_spacing(1)
            end
            context "no kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  state.trm_transform(0,0).should == [64, 700]
                  state.trm_transform(0,1).should == [64, 712]
                  state.trm_transform(1,0).should == [76, 700]
                  state.trm_transform(1,1).should == [76, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  state.trm_transform(0,0).should == [65, 700]
                  state.trm_transform(0,1).should == [65, 712]
                  state.trm_transform(1,0).should == [77, 700]
                  state.trm_transform(1,1).should == [77, 712]
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  state.trm_transform(0,0).should == [63.976, 700]
                  state.trm_transform(0,1).should == [63.976, 712]
                  state.trm_transform(1,0).should == [75.976, 700]
                  state.trm_transform(1,1).should == [75.976, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  state.trm_transform(0,0).should == [64.976, 700]
                  state.trm_transform(0,1).should == [64.976, 712]
                  state.trm_transform(1,0).should == [76.976, 700]
                  state.trm_transform(1,1).should == [76.976, 712]
                end
              end
            end
          end
        end
        context "with character spacing" do
          before do
            state.set_character_spacing(1)
          end
          context "no word spacing" do
            context "no kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  state.trm_transform(0,0).should == [65, 700]
                  state.trm_transform(0,1).should == [65, 712]
                  state.trm_transform(1,0).should == [77, 700]
                  state.trm_transform(1,1).should == [77, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  state.trm_transform(0,0).should == [65, 700]
                  state.trm_transform(0,1).should == [65, 712]
                  state.trm_transform(1,0).should == [77, 700]
                  state.trm_transform(1,1).should == [77, 712]
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  state.trm_transform(0,0).should == [64.976, 700]
                  state.trm_transform(0,1).should == [64.976, 712]
                  state.trm_transform(1,0).should == [76.976, 700]
                  state.trm_transform(1,1).should == [76.976, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  state.trm_transform(0,0).should == [64.976, 700]
                  state.trm_transform(0,1).should == [64.976, 712]
                  state.trm_transform(1,0).should == [76.976, 700]
                  state.trm_transform(1,1).should == [76.976, 712]
                end
              end
            end
          end
          context "with word spacing" do
            before do
              state.set_word_spacing(1)
            end
            context "no kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  state.trm_transform(0,0).should == [65, 700]
                  state.trm_transform(0,1).should == [65, 712]
                  state.trm_transform(1,0).should == [77, 700]
                  state.trm_transform(1,1).should == [77, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  state.trm_transform(0,0).should == [66, 700]
                  state.trm_transform(0,1).should == [66, 712]
                  state.trm_transform(1,0).should == [78, 700]
                  state.trm_transform(1,1).should == [78, 712]
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  state.trm_transform(0,0).should == [64.976, 700]
                  state.trm_transform(0,1).should == [64.976, 712]
                  state.trm_transform(1,0).should == [76.976, 700]
                  state.trm_transform(1,1).should == [76.976, 712]
                end
              end
              context "a word boundary" do

                it "should correctly alter the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  state.trm_transform(0,0).should == [65.976, 700]
                  state.trm_transform(0,1).should == [65.976, 712]
                  state.trm_transform(1,0).should == [77.976, 700]
                  state.trm_transform(1,1).should == [77.976, 712]
                end
              end
            end
          end
        end
      end
    end
  end

end
