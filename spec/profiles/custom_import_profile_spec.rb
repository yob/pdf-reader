require File.dirname(__FILE__) + "/../spec_helper"

class CustomImportProfile
  include Preflight::Profile

  profile_name "custom"

  import Preflight::Profiles::PDFX1A

  rule Preflight::Rules::MinPpi, 300
end

describe "Customised profile that imports the standard PDF/X-1a profile" do

  it "pass a valid PDF/X-1a file" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    preflight = CustomImportProfile.new
    messages  = preflight.check(filename)

    messages.empty?.should be_true
  end

  it "fail a file that isn't PDF/X-1a compliant" do
    filename  = pdf_spec_file("encrypted")
    preflight = CustomImportProfile.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

  it "fail a file that has a 72ppi image" do
    filename  = pdf_spec_file("72ppi")
    preflight = CustomImportProfile.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

  it "pass a file that has a 300ppi image" do
    filename  = pdf_spec_file("300ppi")
    preflight = CustomImportProfile.new
    messages  = preflight.check(filename)

    messages.empty?.should_not be_true
  end

end
