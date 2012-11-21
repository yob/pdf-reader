# coding: utf-8

# All objects that implement the WidthCalculator duck type must conform to
# the contract defined in this file

shared_examples "a WidthCalculator duck type" do
  it "should implement the glyph_width method" do
    subject.should respond_to(:glyph_width)
  end
end
