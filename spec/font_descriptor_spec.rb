# coding: utf-8

require "spec_helper"

describe PDF::Reader::FontDescriptor, "initialisation" do
  let!(:dict) do
    {
      :Ascent       => 10,
      :Descent      => 10,
      :MissingWidth => 500,
      :FontBBox     => [0, 0, 10, 10],
      :AvgWidth     => 40,
      :CapHeight    => 30,
      :Flags        => 1,
      :ItalicAngle  => 0,
      :FontName     => :Helvetica,
      :Leading      => 0,
      :MaxWidth     => 500,
      :StemV        => 0,
      :XHeight      => 0,
      :FontStretch  => :Condensed,
      :FontWeight   => 500,
      :FontFamily   => :BoldItalic
    }
  end
  let!(:objects) { PDF::Reader::ObjectHash.allocate }
  subject        { PDF::Reader::FontDescriptor.new(objects, dict)}

  it "should set the correct instance vars" do
    subject.ascent.should            == 10
    subject.descent.should           == 10
    subject.missing_width.should     == 500
    subject.font_bounding_box.should == [0,0, 10, 10]
    subject.avg_width.should         == 40
    subject.cap_height.should        == 30
    subject.font_flags.should        == 1
    subject.italic_angle.should      == 0
    subject.font_name.should         == "Helvetica"
    subject.leading.should           == 0
    subject.max_width.should         == 500
    subject.stem_v.should            == 0
    subject.x_height.should          == 0
    subject.font_stretch.should      == :Condensed
    subject.font_weight.should       == 500
    subject.font_family.should       == :BoldItalic
  end

end

describe PDF::Reader::FontDescriptor, "#glyph_width" do
  pending
end

describe PDF::Reader::FontDescriptor, "#glyph_to_pdf_scale_factor" do
  pending
end
