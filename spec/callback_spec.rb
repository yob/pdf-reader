# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

# These specs are a safety net to ensure all of our callbacks provide a consistant
# interface across as many files as possible.
#
# Current principles for callback arguments:
#
# * All strings with text will be UTF-8 encoded and marked as such on
#   M17N aware VMs
# * All binary strings will be marked as such on M17N aware
#

describe PDF::Reader do
  include EncodingHelper

  #############################################################################
  # Metadata Callbacks
  #############################################################################

  describe  "pdf_version callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single float argument on #{filename}" do
        receiver.all_args(:pdf_version).each.each do |args|
          assert_equal 1, args.size
          assert args[0].is_a?(Float)
        end
      end
    end
  end

  describe  "metadata callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single hash argument on #{filename}" do
        receiver.all_args(:metadata).each.each do |args|
          assert_equal 1, args.size
          assert args[0].is_a?(Hash)
          check_utf8(args)
        end
      end
    end
  end

  describe  "xml_metadata callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 string argument on #{filename}" do

        receiver.all_args(:xml_metadata).each do |args|
          assert_equal 1, args.size
          assert args[0].is_a?(String)
          check_utf8(args)
        end

      end
    end
  end

  describe  "page_count callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single Fixnum argument that is > 0 on #{filename}" do

        receiver.all_args(:page_count).each do |args|
          assert_equal 1, args.size
          assert args[0].is_a?(Fixnum)
          (args[0] > 0).should  be_true
        end

      end
    end
  end

  #############################################################################
  # Page Callbacks
  #############################################################################

  describe  "begin_inline_image callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:begin_inline_image).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "begin_inline_image_data callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a Hash and binary string argument on #{filename}" do
        receiver.all_args(:begin_inline_image_data).each do |args|
          assert_equal 2, args.size
          assert args[0].is_a?(Hash)
          assert args[1].is_a?(String)
          check_utf8(args[0])
          check_binary(args[1])
        end

      end
      it "should return a string with a length that matches the specified dimensions on #{filename}" do
        receiver.all_args(:begin_inline_image_data).each do |args|
          width  = args[0][:W]
          height = args[0][:H]
          bits   = args[0][:BPC] || 1
          case args[0][:CS]
          when :RGB  then bytes_per_pixel = bits * 3 / 8.0
          when :G    then bytes_per_pixel = bits * 1 / 8.0
          when :CMYK then bytes_per_pixel = bits * 4 / 8.0
          else
            bytes_per_pixel = bits / 8.0
          end
          length = (width * height * bytes_per_pixel).to_i
          assert_equal length, args[1].size
        end

      end
    end
  end

  describe  "begin_text_object callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:begin_text_object).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "end_document callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:end_document).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "end_inline_image callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do

        receiver.all_args(:end_inline_image).each do |args|
          assert_equal [], args
        end

      end
    end
  end

  describe  "end_page callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:end_page).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "end_page_container callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:end_page_container).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "end_text_object callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:end_text_object).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "move_to_next_line_and_show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 strings on #{filename}" do
        receiver.all_args(:move_to_next_line_and_show_text).each do |args|
          assert_equal 1, args.size
          assert args[0].is_a? String
          check_utf8(args)
        end
      end
    end
  end

  describe  "restore_graphics_state callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:restore_graphics_state).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "save_graphics_state callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:save_graphics_state).each do |args|
          assert_equal [], args
        end
      end
    end
  end

  describe  "set_text_font_and_size callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do
        receiver.all_args(:set_text_font_and_size).each do |args|
          assert_equal 2, args.size
          assert args[0].is_a? Symbol
          assert args[1].is_a? Numeric
        end
      end
    end
  end

  describe  "show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 string argument on #{filename}" do
        receiver.all_args(:show_text).each do |args|
          assert_equal 1, args.size
          assert args[0].is_a? String
          check_utf8(args)
        end
      end
    end
  end

  describe  "show_text_with_positioning callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return an array of Numbers and UTF-8 strings on #{filename}" do
        receiver.all_args(:show_text_with_positioning).each do |args|
          args[0].each do |arg|
            assert arg.class == String || arg.class == Fixnum || arg.class == Float
          end
          check_utf8(args)
        end
      end
    end
  end

  describe  "set_spacing_next_line_show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 strings on #{filename}" do
        receiver.all_args(:set_spacing_next_line_show_text).each do |args|
          assert_equal 3, args.size
          assert args[0].is_a?(Numeric)
          assert args[1].is_a?(Numeric)
          assert args[2].is_a?(String)
          check_utf8(args)
        end
      end
    end
  end

end
