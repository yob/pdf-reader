# typed: false
# coding: utf-8

# These specs are an integration safety net to ensure all of our callbacks provide a consistant
# interface across as many files as possible.

describe PDF::Reader do
  include EncodingHelper

  describe  "begin_inline_image callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:begin_inline_image).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "begin_inline_image_data callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns an even number of arguments on #{filename}" do
        receiver.all_args(:begin_inline_image_data).each do |args|
          expect(args.size).to be_even
        end
      end
    end
  end

  describe  "begin_text_object callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:begin_text_object).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "end_document callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:end_document).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "end_inline_image callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns a binary string on #{filename}" do
        receiver.all_args(:end_inline_image).each do |args|
          expect(args.size).to eq 1
          check_binary(args)
        end
      end
    end
  end

  describe  "end_page callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:end_page).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "end_page_container callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:end_page_container).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "end_text_object callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:end_text_object).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "move_to_next_line_and_show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns a single binary strings on #{filename}" do
        receiver.all_args(:move_to_next_line_and_show_text).each do |args|
          expect(args.size).to eq 1
          expect(args[0]).to be_a(String)
          check_binary(args)
        end
      end
    end
  end

  describe  "restore_graphics_state callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:restore_graphics_state).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "save_graphics_state callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:save_graphics_state).each do |args|
          expect(args).to eq([])
        end
      end
    end
  end

  describe  "set_text_font_and_size callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns no arguments on #{filename}" do
        receiver.all_args(:set_text_font_and_size).each do |args|
          expect(args.size).to eq 2
          expect(args[0]).to be_a(Symbol)
          expect(args[1]).to be_a(Numeric)
        end
      end
    end
  end

  describe  "show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns a single binary string argument on #{filename}" do
        receiver.all_args(:show_text).each do |args|
          expect(args.size).to eq 1
          expect(args[0]).to be_a(String)
          check_binary(args)
        end
      end
    end
  end

  describe  "show_text_with_positioning callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns an array of Numbers and binary strings on #{filename}" do
        receiver.all_args(:show_text_with_positioning).each do |args|
          args[0].each do |arg|
            expect(String === arg || Integer === arg || Float === arg).to eq true
          end
          check_binary(args)
        end
      end
    end
  end

  describe  "set_spacing_next_line_show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "returns a single binary strings on #{filename}" do
        receiver.all_args(:set_spacing_next_line_show_text).each do |args|
          expect(args.size).to eq 3
          expect(args[0]).to be_a(Numeric)
          expect(args[1]).to be_a(Numeric)
          expect(args[2]).to be_a(String)
          check_binary(args)
        end
      end
    end
  end

end
