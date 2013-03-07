# encoding: utf-8

require File.dirname(__FILE__) + "/../spec_helper"

describe PDF::Reader::RegisterReceiver do
  subject { PDF::Reader::RegisterReceiver.new }

  context "instance" do
    it "responds to any method" do
      subject.should respond_to(:foo)
    end

    context "with callbacks recorded" do
      before do
        subject.foo(:bar)
        subject.foo(:baz)
      end

      let(:foo_bar) { { :name => :foo, :args => [:bar] } }
      let(:foo_baz) { { :name => :foo, :args => [:baz] } }

      it "counts correctly" do
        subject.count(:foo).should == 2
        subject.count(:other).should == 0
      end

      it "returns callbacks recorded" do
        subject.all(:foo).should eq [ foo_bar, foo_baz ]
        subject.all(:other).should be_empty
      end

      it "returns callback args" do
        subject.all_args(:foo).should eq [[:bar], [:baz]]
        subject.all_args(:other).should be_empty
      end

      it "finds first occurance" do
        subject.first_occurance_of(:foo).should eq foo_bar
        subject.first_occurance_of(:other).should be_nil
      end

      it "finds final occurance" do
        subject.final_occurance_of(:foo).should eq foo_baz
        subject.final_occurance_of(:other).should be_nil
      end

      describe "series()" do
        it "none for no methods" do
          subject.series.should be_nil
        end

        it "none for unmatched methods" do
          subject.series(:other).should be_nil
          subject.series(:foo, :other).should be_nil
          subject.series(:foo, :foo, :foo).should be_nil
        end

        it "matches series" do
          subject.series(:foo).should eq [ foo_bar ]
          subject.series(:foo, :foo).should eq [ foo_bar, foo_baz ]
        end
      end
    end
  end
end
