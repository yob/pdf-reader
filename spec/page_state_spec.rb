# typed: false
# coding: utf-8

describe PDF::Reader::PageState do
  let!(:page)   { double(:cache => {},
                        :objects => {},
                        :fonts => {},
                        :xobjects => {},
                        :color_spaces => {},
                        :rotate => 0)}

  describe "#DEFAULT_GRAPHICS_STATE" do
    subject { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE }

    context "when walking more than one page" do
      let!(:expected) { PDF::Reader::PageState::DEFAULT_GRAPHICS_STATE.dup }

      before do
        2.times do
          state = PDF::Reader::PageState.new(page)
          state.save_graphics_state
          state.concatenate_matrix(1,2,3,4,5,6)
        end
      end

      it "does not mutate" do
        expect(subject).to eql(expected)
      end
    end
  end

  describe "#save_graphics_state" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "increases the stack depth by one" do
        expect {
          state.save_graphics_state
        }.to change(state, :stack_depth).from(1).to(2)
      end
    end
  end

  describe "#restore_graphics_state" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "reduces the stack depth by one" do
        state.save_graphics_state

        expect {
          state.restore_graphics_state
        }.to change(state, :stack_depth).from(2).to(1)
      end
    end
  end

  describe "#concatenate_matrix" do
    let!(:state)  {PDF::Reader::PageState.new(page) }

    context "when changing value a" do
      it "multiplies the matrixes" do
        state.concatenate_matrix(2, 0,
                                 0, 1,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.ctm_transform(0,0)).to eq([0, 0])
        expect(state.ctm_transform(0,1)).to eq([0, 1])
        expect(state.ctm_transform(1,0)).to eq([2, 0])
        expect(state.ctm_transform(1,1)).to eq([2, 1])
      end
    end

    context "when changing value b" do
      it "multiplies the matrixes" do
        state.concatenate_matrix(1, 2,
                                 0, 1,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.ctm_transform(0,0)).to eq([0, 0])
        expect(state.ctm_transform(0,1)).to eq([0, 1])
        expect(state.ctm_transform(1,0)).to eq([1, 2])
        expect(state.ctm_transform(1,1)).to eq([1, 3])
      end
    end

    context "when changing value c" do
      it "multiplies the matrixes" do
        state.concatenate_matrix(1, 0,
                                 2, 1,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.ctm_transform(0,0)).to eq([0, 0])
        expect(state.ctm_transform(0,1)).to eq([2, 1])
        expect(state.ctm_transform(1,0)).to eq([1, 0])
        expect(state.ctm_transform(1,1)).to eq([3, 1])
      end
    end

    context "when changing value d" do
      it "multiplies the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 2,
                                 0, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.ctm_transform(0,0)).to eq([0, 0])
        expect(state.ctm_transform(0,1)).to eq([0, 2])
        expect(state.ctm_transform(1,0)).to eq([1, 0])
        expect(state.ctm_transform(1,1)).to eq([1, 2])
      end
    end

    context "when changing value e" do
      it "multiplies the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 2, 0)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.ctm_transform(0,0)).to eq([2, 0])
        expect(state.ctm_transform(0,1)).to eq([2, 1])
        expect(state.ctm_transform(1,0)).to eq([3, 0])
        expect(state.ctm_transform(1,1)).to eq([3, 1])
      end
    end

    context "when changing value f" do
      it "multiplies the matrixes" do
        state.concatenate_matrix(1, 0,
                                 0, 1,
                                 0, 2)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.ctm_transform(0,0)).to eq([0, 2])
        expect(state.ctm_transform(0,1)).to eq([0, 3])
        expect(state.ctm_transform(1,0)).to eq([1, 2])
        expect(state.ctm_transform(1,1)).to eq([1, 3])
      end
    end

    context "when applying a rotation followed by a translation" do
      it "multiplies the matrixes using pre-multiplication" do
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
        expect(state.ctm_transform(0,0)).to eq([-10,10])
        expect(state.ctm_transform(0,1)).to eq([-11,10])
        expect(state.ctm_transform(1,0)).to eq([-10,11])
        expect(state.ctm_transform(1,1)).to eq([-11,11])
      end
    end
  end

  describe "#begin_text_object" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "initialzes the text_matrix to ensure text is positioned at 0,0" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)

        expect(state.trm_transform(0,0)).to eq([0,0])
        expect(state.trm_transform(0,1)).to eq([0, 12])
        expect(state.trm_transform(1,0)).to eq([12, 0])
        expect(state.trm_transform(1,1)).to eq([12, 12])
      end
    end
  end

  describe "#move_text_position" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position(5, 10)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([5,10])
        expect(state.trm_transform(0,1)).to eq([5, 22])
        expect(state.trm_transform(1,0)).to eq([17, 10])
        expect(state.trm_transform(1,1)).to eq([17, 22])
      end
    end
  end

  describe "#move_text_position_and_set_leading" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position_and_set_leading(5, 10)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([5, 10])
        expect(state.trm_transform(0,1)).to eq([5, 22])
        expect(state.trm_transform(1,0)).to eq([17, 10])
        expect(state.trm_transform(1,1)).to eq([17, 22])
      end

      it "alters the text leading" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.move_text_position_and_set_leading(5, 10)

        expect(state.clone_state[:text_leading]).to eq(-10)
      end
    end
  end

  describe "#set_text_matrix_and_text_line_matrix" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_matrix_and_text_line_matrix(1, 2, 3, 4, 5, 6)

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([5, 6])
        expect(state.trm_transform(0,1)).to eq([41, 54])
        expect(state.trm_transform(1,0)).to eq([17, 30])
        expect(state.trm_transform(1,1)).to eq([53.0, 78.0])
      end
    end
  end

  describe "#move_to_start_of_next_line" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_leading(15)
        state.move_to_start_of_next_line

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([0, -15])
        expect(state.trm_transform(0,1)).to eq([0, -3])
        expect(state.trm_transform(1,0)).to eq([12, -15])
        expect(state.trm_transform(1,1)).to eq([12, -3])
      end
    end
  end

  describe "#move_to_next_line_and_show_text" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_leading(15)
        state.move_to_next_line_and_show_text("Foo")

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([0, -15])
        expect(state.trm_transform(0,1)).to eq([0, -3])
        expect(state.trm_transform(1,0)).to eq([12, -15])
        expect(state.trm_transform(1,1)).to eq([12, -3])
      end
    end
  end

  describe "#move_to_next_line_and_show_text" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_text_leading(15)
        state.move_to_next_line_and_show_text("Foo")

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([0, -15])
        expect(state.trm_transform(0,1)).to eq([0, -3])
        expect(state.trm_transform(1,0)).to eq([12, -15])
        expect(state.trm_transform(1,1)).to eq([12, -3])
      end
    end
  end

  describe "#set_spacing_next_line_show_text" do
    context "with an empty page" do
      let!(:state)  {PDF::Reader::PageState.new(page) }

      it "sets word spacing" do
        state.begin_text_object
        state.set_spacing_next_line_show_text(10, 20, "test")
        expect(state.clone_state[:word_spacing]).to eq(10)
      end

      it "sets character spacing" do
        state.begin_text_object
        state.set_spacing_next_line_show_text(10, 20, "test")
        expect(state.clone_state[:char_spacing]).to eq(20)
      end

      it "alters the text position" do
        state.begin_text_object
        state.set_text_font_and_size(:Test, 12)
        state.set_spacing_next_line_show_text(10, 20, "test")

        # how the matrix is stored and multiplied is really an implementation
        # detail, so it's better to check the results indirectly via the API
        # external collaborators will use
        expect(state.trm_transform(0,0)).to eq([0, 0])
        expect(state.trm_transform(0,1)).to eq([0, 12])
        expect(state.trm_transform(1,0)).to eq([12, 0])
        expect(state.trm_transform(1,1)).to eq([12, 12])
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
        expect(state.trm_transform(0,0)).to eq([40, 700])
        expect(state.trm_transform(0,1)).to eq([40, 712])
        expect(state.trm_transform(1,0)).to eq([52, 700])
        expect(state.trm_transform(1,1)).to eq([52, 712])
      end

      context "2pt glyph width" do
        context "no character spacing" do
          context "no word spacing" do
            context "no kerning" do
              context "not a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  expect(state.trm_transform(0,0)).to eq([64, 700])
                  expect(state.trm_transform(0,1)).to eq([64, 712])
                  expect(state.trm_transform(1,0)).to eq([76, 700])
                  expect(state.trm_transform(1,1)).to eq([76, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  expect(state.trm_transform(0,0)).to eq([64, 700])
                  expect(state.trm_transform(0,1)).to eq([64, 712])
                  expect(state.trm_transform(1,0)).to eq([76, 700])
                  expect(state.trm_transform(1,1)).to eq([76, 712])
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
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

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  expect(state.trm_transform(0,0)).to eq([64, 700])
                  expect(state.trm_transform(0,1)).to eq([64, 712])
                  expect(state.trm_transform(1,0)).to eq([76, 700])
                  expect(state.trm_transform(1,1)).to eq([76, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  expect(state.trm_transform(0,0)).to eq([65, 700])
                  expect(state.trm_transform(0,1)).to eq([65, 712])
                  expect(state.trm_transform(1,0)).to eq([77, 700])
                  expect(state.trm_transform(1,1)).to eq([77, 712])
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
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

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  expect(state.trm_transform(0,0)).to eq([65, 700])
                  expect(state.trm_transform(0,1)).to eq([65, 712])
                  expect(state.trm_transform(1,0)).to eq([77, 700])
                  expect(state.trm_transform(1,1)).to eq([77, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  expect(state.trm_transform(0,0)).to eq([65, 700])
                  expect(state.trm_transform(0,1)).to eq([65, 712])
                  expect(state.trm_transform(1,0)).to eq([77, 700])
                  expect(state.trm_transform(1,1)).to eq([77, 712])
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
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

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, false)

                  expect(state.trm_transform(0,0)).to eq([65, 700])
                  expect(state.trm_transform(0,1)).to eq([65, 712])
                  expect(state.trm_transform(1,0)).to eq([77, 700])
                  expect(state.trm_transform(1,1)).to eq([77, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 0, true)

                  expect(state.trm_transform(0,0)).to eq([66, 700])
                  expect(state.trm_transform(0,1)).to eq([66, 712])
                  expect(state.trm_transform(1,0)).to eq([78, 700])
                  expect(state.trm_transform(1,1)).to eq([78, 712])
                end
              end
            end
            context "2pt kerning" do
              context "not a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, false)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
                end
              end
              context "a word boundary" do

                it "alters the text matrix" do
                  state.process_glyph_displacement(2, 2, true)

                  expect(state.trm_transform(0,0)).to eq([63.976, 700])
                  expect(state.trm_transform(0,1)).to eq([63.976, 712])
                  expect(state.trm_transform(1,0)).to eq([75.976, 700])
                  expect(state.trm_transform(1,1)).to eq([75.976, 712])
                end
              end
            end
          end
        end
      end
    end
  end

end
