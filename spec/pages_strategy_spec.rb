# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

class PDF::Reader::PagesStrategy
  public :content_stream
end

describe PDF::Reader::PagesStrategy do

  let(:object_hash) { PDF::Reader::ObjectHash.allocate }
  let(:font) { PDF::Reader::Font.new(object_hash, {}) }

  context "processing instructions containing a single text block" do
    it "should send the correct callbacks" do

      # mock up an object that will be called with callbacks. This will test that
      # the content class correctly recognises all instructions
      receiver = double("receiver")
      expect(receiver).to receive(:begin_text_object).once             # BT
      expect(receiver).to receive(:move_text_position).once            # Td
      expect(receiver).to receive(:set_text_font_and_size).once        # Tf
      expect(receiver).to receive(:set_text_rendering_mode).once       # Tr
      expect(receiver).to receive(:show_text).once                     # Tj
      expect(receiver).to receive(:end_text_object).once               # ET

      # The instructions to test with
      instructions = "BT\n 36.000 794.330 Td\n /F1 10.0 Tf\n 0 Tr\n (047174719X) Tj\n ET"

      # process the instructions
      content = PDF::Reader::PagesStrategy.new(nil, receiver)
      content.content_stream(instructions, {:F1 => font})
    end
  end

  it "should send the correct callbacks when processing instructions containing 2 text blocks" do

    # mock up an object that will be called with callbacks. This will test that
    # the content class correctly recognises all instructions
    receiver = double("receiver")
    expect(receiver).to receive(:begin_text_object).twice            # BT
    expect(receiver).to receive(:move_text_position).twice           # Td
    expect(receiver).to receive(:set_text_font_and_size).twice       # Tf
    expect(receiver).to receive(:set_text_rendering_mode).twice      # Tr
    expect(receiver).to receive(:show_text).twice                    # Tj
    expect(receiver).to receive(:end_text_object).twice              # ET

    # The instructions to test with
    instructions = "BT 36.000 794.330 Td /F1 10.0 Tf 0 Tr (047174719X) Tj ET\n BT 36.000 782.770 Td /F1 10.0 Tf 0 Tr (9780300110562) Tj ET"

    # process the instructions
    content = PDF::Reader::PagesStrategy.new(nil, receiver)
    content.content_stream(instructions, {:F1 => font})
  end

  it "should send the correct callbacks when processing instructions containing an inline image" do

    # mock up an object that will be called with callbacks. This will test that
    # the content class correctly recognises all instructions
    receiver = double("receiver")
    expect(receiver).to receive(:begin_inline_image).once   # BI
    expect(receiver).to receive(:begin_inline_image_data).once    # ID
    expect(receiver).to receive(:end_inline_image).once     # EI

    # access a content stream with an inline image
    filename = pdf_spec_file("inline_image")
    io       = File.new(filename, "r")
    ohash    = PDF::Reader::ObjectHash.new(io)
    ref      = PDF::Reader::Reference.new(3,0)
    obj      = ohash[ref]

    # process the instructions
    content = PDF::Reader::PagesStrategy.new(nil, receiver)
    fonts = {:F9 => font,
             :F8 => font,
             :Fb => font}
    content.content_stream(obj, fonts)
  end

  # test for a bug reported by Jack Rusher where params at the end of a stream would be
  # silently dropped if their matching operator was in the next contream stream in a series
  it "should send the correct callbacks when processing a PDF with content over multiple streams" do

    receiver = PDF::Reader::RegisterReceiver.new

    filename = pdf_spec_file("split_params_and_operator")
    PDF::Reader.file(filename, receiver)

    text_callbacks = receiver.all(:show_text_with_positioning)
    expect(text_callbacks.size).to eql(2)
    expect(text_callbacks[0][:args]).to eql([["My name is"]])
    expect(text_callbacks[1][:args]).to eql([["James Healy"]])
  end

  it "should send the correct callbacks when using more than one receiver" do

    # mock up an object that will be called with callbacks. This will test that
    # the content class correctly recognises all instructions
    one = double("receiver_one")
    expect(one).to receive(:move_text_position).once # Td

    two = double("receiver_two")
    expect(two).to receive(:move_text_position).once # Td

    # The instructions to test with
    instructions = "36.000 794.330 Td"

    # process the instructions
    content = PDF::Reader::PagesStrategy.new(nil, [one, two])
    content.content_stream(instructions)
  end
end
