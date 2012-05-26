# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Transform do
  let(:transform) { PDF::Reader::Transform.new }

  it "transforms a literal string" do
    str = [{ :string_literal => "abc"}]
    transform.apply(str).should == %w{ abc }
  end

  it "transforms a an empty literal string" do
    ast = [{ :string_literal => [] }]
    transform.apply(ast).should == [ "" ]
  end

  it "transforms a nested literal string" do
    ast = [{ :string_literal => [{:string_literal => "abc"}] }]
    transform.apply(ast).should == [ "abc" ]
  end

  it "transforms a hex string without captials" do
    str = [{ :string_hex => "00ffab"}]
    transform.apply(str).should == [ binary_string("\x00\xff\xab") ]
  end

  it "transforms a hex string with spaces" do
    str = [{ :string_hex => "00ff ab"}]
    transform.apply(str).should == [ binary_string("\x00\xff\xab") ]
  end

  it "transforms a hex string with an odd number of characters" do
    str = [{ :string_hex => "00ffa"}]
    transform.apply(str).should == [ binary_string("\x00\xff\xa0") ]
  end

  it "transforms a PDF Name to a ruby symbol" do
    str = [{ :name => "James"}]
    transform.apply(str).should == [ :James ]
  end

  it "transforms a PDF Name with encoded bytes to a ruby symbol" do
    str = [{ :name => "James#20Healy"}]
    transform.apply(str).should == [ :"James Healy" ]
  end

  it "transforms a PDF Name with encoded bytes to a ruby symbol" do
    str = [{ :name => "James#23Healy"}]
    transform.apply(str).should == [ :"James#Healy" ]
  end

  it "transforms a PDF Name with encoded bytes to a ruby symbol" do
    str = [{ :name => "Ja#6des"}]
    transform.apply(str).should == [ :"James" ]
  end

  it "transforms a float" do
    str = [{ :float => "1.9"}]
    transform.apply(str).should == [ 1.9 ]
  end

  it "transforms an int" do
    str = [{ :float => "10"}]
    transform.apply(str).should == [ 10 ]
  end

  it "transforms a true boolean" do
    str = [{ :boolean => "true"}]
    transform.apply(str).should == [ true ]
  end

  it "transforms a false boolean" do
    str = [{ :boolean => "false"}]
    transform.apply(str).should == [ false ]
  end

  it "transforms a null" do
    str = [{ :null => "null"}]
    transform.apply(str).should == [ nil ]
  end

  it "transforms an array" do
    ast = [
      { :array => [
        {:integer => "1"},
        {:integer => "2"},
        {:integer => "3"},
        {:integer => "4"}
        ]
      }
    ]
    transform.apply(ast).should == [ [1, 2, 3, 4] ]
  end

  it "transforms a dict" do
    ast = [
      { :dict => [
        {:name => "One"},
        {:integer => "1"},
        {:name => "Two"},
        {:integer => "2"}
        ]
      }
    ]
    transform.apply(ast).should == [ {:One => 1, :Two => 2} ]
  end

  it "transforms an indirect reference" do
    # TODO this should actually transform the reference into a
    #      PDF::Reader::Reference object
    ast = [ {:indirect => "1 0 R"} ]
    transform.apply(ast).should == [ "1 0 R" ]
  end

  it "transforms a PDF keyword" do
    ast = [ {:keyword => "endstream"} ]
    transform.apply(ast).should == [ "endstream" ]
  end
end
