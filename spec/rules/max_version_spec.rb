require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MaxVersion do

  it "correctly fail files with a higher version" do
    filename  = pdf_spec_file("version_1_4")
    receiver = Preflight::Rules::MaxVersion.new("1.3")
    PDF::Reader.file(filename, receiver)

    receiver.messages.should_not be_empty
  end

  it "correctly pass files with an equal version" do
    filename  = pdf_spec_file("version_1_4")
    receiver = Preflight::Rules::MaxVersion.new("1.4")
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "correctly pass files with a lower version" do
    filename  = pdf_spec_file("version_1_4")
    receiver = Preflight::Rules::MaxVersion.new("1.5")
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

end
