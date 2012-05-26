# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Transform, "#transform" do
  let!(:transform) { PDF::Reader::Transform.new }

  context "literal string" do
    let!(:ast) { [{ :string_literal => "abc"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == %w{ abc }
    end
  end

  context "empty literal string" do
    let!(:ast) { [{ :string_literal => [] }] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ "" ]
    end
  end

  context "nested literal string" do
    let!(:ast)  { [{ :string_literal => [{:string_literal => "abc"}] }] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ "abc" ]
    end
  end

  context "PDF Hex string without capitals" do
    let!(:ast) { [{ :string_hex => "00ffab"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ binary_string("\x00\xff\xab") ]
    end
  end

  context "PDF Hex string with spaces" do
    let!(:ast) { [{ :string_hex => "00ff ab"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ binary_string("\x00\xff\xab") ]
    end
  end

  context "PDF Hex string with an odd number of characters" do
    let!(:ast) { [{ :string_hex => "00ffa"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ binary_string("\x00\xff\xa0") ]
    end
  end

  context "PDF Name" do
    let!(:ast) { [{ :name => "James"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ :James ]
    end
  end

  context "PDF Name with encoded bytes" do
    let!(:ast) { [{ :name => "James#20Healy"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ :"James Healy" ]
    end
  end

  context "PDF Name with encoded bytes" do
    let!(:ast) { [{ :name => "James#23Healy"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ :"James#Healy" ]
    end
  end

  context "PDF Name with encoded bytes to a ruby symbol" do
    let!(:ast) { [{ :name => "Ja#6des"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ :"James" ]
    end
  end

  context "PDF float" do
    let!(:ast) { [{ :float => "1.9"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ 1.9 ]
    end
  end

  context "PDF int" do
    let!(:ast) { [{ :float => "10"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ 10 ]
    end
  end

  context "PDF true" do
    let!(:ast) { [{ :boolean => "true"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ true ]
    end
  end

  context "PDF false" do
    let!(:ast) { [{ :boolean => "false"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ false ]
    end
  end

  context "PDF null" do
    let!(:ast) { [{ :null => "null"}] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ nil ]
    end
  end

  context "PDF array" do
    let!(:ast) {
      [
        { :array => [
          {:integer => "1"},
          {:integer => "2"},
          {:integer => "3"},
          {:integer => "4"}
          ]
        }
      ]
    }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ [1, 2, 3, 4] ]
    end
  end

  context "PDF dict" do
    let!(:ast) {
      [
        { :dict => [
          {:name => "One"},
          {:integer => "1"},
          {:name => "Two"},
          {:integer => "2"}
          ]
        }
      ]
    }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ {:One => 1, :Two => 2} ]
    end
  end

  context "Indirect Reference" do
    let!(:ast) { [ {:indirect => "1 0 R"} ] }

    # TODO this should actually transform the reference into a
    #      PDF::Reader::Reference object
    it "should be transformed into tokens" do
      transform.apply(ast).should == [ "1 0 R" ]
    end
  end

  context "PDF Keywords" do
    let!(:ast) { [ {:keyword => "endstream"} ] }

    it "should be transformed into tokens" do
      transform.apply(ast).should == [ "endstream" ]
    end
  end

  context "operators" do
    let!(:ast) { [ {:op => "q"}, {:op => "Q"} ] }

    it "should be trasformed into tokens" do
      transform.apply(ast).should == [ "q", "Q" ]
    end

    it "should be transformed into Strings" do
      transform.apply(ast).map(&:class).should == [ String, String ]
    end
  end

end
