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
    expect(subject.ascent).to            eq(10)
    expect(subject.descent).to           eq(10)
    expect(subject.missing_width).to     eq(500)
    expect(subject.font_bounding_box).to eq([0,0, 10, 10])
    expect(subject.avg_width).to         eq(40)
    expect(subject.cap_height).to        eq(30)
    expect(subject.font_flags).to        eq(1)
    expect(subject.italic_angle).to      eq(0)
    expect(subject.font_name).to         eq("Helvetica")
    expect(subject.leading).to           eq(0)
    expect(subject.max_width).to         eq(500)
    expect(subject.stem_v).to            eq(0)
    expect(subject.x_height).to          eq(0)
    expect(subject.font_stretch).to      eq(:Condensed)
    expect(subject.font_weight).to       eq(500)
    expect(subject.font_family).to       eq(:BoldItalic)
  end

end

describe PDF::Reader::FontDescriptor, "#glyph_width" do
  pending
end

describe PDF::Reader::FontDescriptor, "#glyph_to_pdf_scale_factor" do
  pending
end
