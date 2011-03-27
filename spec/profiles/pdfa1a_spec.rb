require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Profiles::PDFA1A do

  it "correctly pass a valid PDF/A-1a file" do
    filename  = pdf_spec_file("pdfa-1a")
    preflight = Preflight::Profiles::PDFA1A.new
    messages  = preflight.check(filename)

    puts messages.inspect
    messages.empty?.should be_true
  end

end
