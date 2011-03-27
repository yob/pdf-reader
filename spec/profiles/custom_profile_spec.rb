require File.dirname(__FILE__) + "/../spec_helper"

class CustomProfile
  include Preflight::Profile

  profile_name "custom"

  rule Preflight::Rules::MaxVersion, 1.3
end

describe "Customised profile" do

  it "fail files with a higher version" do
    filename = pdf_spec_file("version_1_4")
    preflight = CustomProfile.new
    messages  = preflight.check(filename)

    messages.should_not be_empty
  end

  it "pass files with an equal version" do
    filename  = pdf_spec_file("version_1_3")
    preflight = CustomProfile.new
    messages  = preflight.check(filename)

    messages.should be_empty
  end

end
