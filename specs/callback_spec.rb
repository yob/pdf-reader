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

context PDF::Reader do
  include EncodingHelper

  #############################################################################
  # Metadata Callbacks
  #############################################################################

  context  "pdf_version callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single float argument on #{filename}" do
        receiver.all_args(:pdf_version).each do |args|
          args.size.should eql(1)
          args[0].should   be_a_kind_of(Float)
        end
      end
    end
  end

  context  "metadata callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single hash argument on #{filename}" do
        receiver.all_args(:metadata).each do |args|
          args.size.should eql(1)
          args[0].should   be_a_kind_of(Hash)
          check_utf8(args)
        end
      end
    end
  end

  context  "xml_metadata callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 string argument on #{filename}" do

        receiver.all_args(:xml_metadata) do |args|
          args.size.should eql(1)
          args[0].should   be_a_kind_of(String)
          check_utf8(args)
        end

      end
    end
  end

  context  "page_count callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single Fixnum argument that is > 0 on #{filename}" do

        receiver.all_args(:page_count) do |args|
          args.size.should      eql(1)
          args[0].should        be_a_kind_of(Fixnum)
          (args[0] > 0).should  be_true
        end

      end
    end
  end

  #############################################################################
  # Page Callbacks
  #############################################################################

  context  "begin_inline_image callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do

        receiver.all_args(:begin_inline_image) do |args|
          args.should be_empty
        end

      end
    end
  end

  context  "begin_inline_image_data callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a Hash and binary string argument on #{filename}" do
        receiver.all_args(:begin_inline_image_data) do |args|
          args.size.should eql(2)
          args[0].should   be_a_kind_of(Hash)
          args[1].should   be_a_kind_of(String)
          check_utf8(args[0])
          check_binary(args[1])
        end

      end
      it "should return a string with a length that matches the specified dimensions on #{filename}" do
        receiver.all_args(:begin_inline_image_data) do |args|
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
          args[1].size.should eql((width * height * bytes_per_pixel).to_i)
        end

      end
    end
  end

  context  "end_inline_image callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return no arguments on #{filename}" do

        receiver.all_args(:end_inline_image) do |args|
          args.should be_empty
        end

      end
    end
  end

  context  "show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 string argument on #{filename}" do
        receiver.all_args(:show_text) do |args|
          args.size.should eql(1)
          args[0].should   be_a_kind_of(String)
          check_utf8(args)
        end
      end
    end
  end

  context  "show_text_with_positioning callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return an array of Numbers and UTF-8 strings on #{filename}" do
        receiver.all_args(:show_text_with_positioning) do |args|
          args[0].each do |arg|
            (arg.class == String || arg.class == Fixnum || arg.class == Float).should   be_true
          end
          check_utf8(args)
        end
      end
    end
  end

  context  ":move_to_next_line_and_show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 strings on #{filename}" do
        receiver.all_args(:move_to_next_line_and_show_text) do |args|
          args.size.should eql(1)
          args[0].should   be_a_kind_of(String)
          check_utf8(args)
        end
      end
    end
  end

  context  "set_spacing_next_line_show_text callback" do
    CallbackHelper.instance.good_receivers.each do |filename, receiver|
      it "should return a single UTF-8 strings on #{filename}" do
        receiver.all_args(:set_spacing_next_line_show_text) do |args|
          args.size.should eql(3)
          args[0].should   be_a_kind_of(Numeric)
          args[1].should   be_a_kind_of(Numeric)
          args[2].should   be_a_kind_of(String)
          check_utf8(args)
        end
      end
    end
  end

end
