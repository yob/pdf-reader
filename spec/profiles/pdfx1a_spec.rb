require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Profiles::PDFX1A do

  it "correctly pass a valid PDF/X-1a file that uses font subsetting" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.empty?.should be_true
  end

  it "correctly pass a valid PDF/X-1a file that doesn't use font subsetting" do
    filename  = pdf_spec_file("pdfx-1a-no-subsetting")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.empty?.should be_true
  end

  it "correctly detect files with an incompatible version" do
    filename  = pdf_spec_file("version_1_4")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

  it "correctly detect encrypted files" do
    filename  = pdf_spec_file("encrypted")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

end
