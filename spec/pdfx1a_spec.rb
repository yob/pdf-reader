require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Preflight::PDFX1A do

  it "correctly detect files with an incompatible version" do
    filename  = pdf_spec_file("version_1_4")
    preflight = PDF::Preflight::PDFX1A.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

  it "correctly detect encrypted files" do
    filename  = pdf_spec_file("encrypted")
    preflight = PDF::Preflight::PDFX1A.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

end
