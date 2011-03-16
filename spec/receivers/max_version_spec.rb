require File.dirname(__FILE__) + "/../spec_helper"

describe PDF::Preflight::Receivers::MaxVersion do

  it "correctly fail files with a higher version" do
    filename  = pdf_spec_file("version_1_4")
    receiver = PDF::Preflight::Receivers::MaxVersion.new("1.3")
    PDF::Reader.file(filename, receiver)

    receiver.message.should_not be_nil
  end

  it "correctly pass files with an equal version" do
    filename  = pdf_spec_file("version_1_4")
    receiver = PDF::Preflight::Receivers::MaxVersion.new("1.4")
    PDF::Reader.file(filename, receiver)

    receiver.message.should be_nil
  end

  it "correctly pass files with a lower version" do
    filename  = pdf_spec_file("version_1_4")
    receiver = PDF::Preflight::Receivers::MaxVersion.new("1.5")
    PDF::Reader.file(filename, receiver)

    receiver.message.should be_nil
  end

end
