# typed: false
# encoding: utf-8

describe PDF::Reader::RegisterReceiver do
  subject { PDF::Reader::RegisterReceiver.new }

  context "instance" do
    it "responds to any method" do
      expect(subject).to respond_to(:foo)
    end

    context "with callbacks recorded" do
      before do
        subject.foo(:bar)
        subject.foo(:baz)
      end

      let(:foo_bar) { { :name => :foo, :args => [:bar] } }
      let(:foo_baz) { { :name => :foo, :args => [:baz] } }

      it "counts correctly" do
        expect(subject.count(:foo)).to eq(2)
        expect(subject.count(:other)).to eq(0)
      end

      it "returns callbacks recorded" do
        expect(subject.all(:foo)).to eq [ foo_bar, foo_baz ]
        expect(subject.all(:other)).to be_empty
      end

      it "returns callback args" do
        expect(subject.all_args(:foo)).to eq [[:bar], [:baz]]
        expect(subject.all_args(:other)).to be_empty
      end

      it "finds first occurance" do
        expect(subject.first_occurance_of(:foo)).to eq foo_bar
        expect(subject.first_occurance_of(:other)).to be_nil
      end

      it "finds final occurance" do
        expect(subject.final_occurance_of(:foo)).to eq foo_baz
        expect(subject.final_occurance_of(:other)).to be_nil
      end

      describe "series()" do
        it "none for no methods" do
          expect(subject.series).to be_nil
        end

        it "none for unmatched methods" do
          expect(subject.series(:other)).to be_nil
          expect(subject.series(:foo, :other)).to be_nil
          expect(subject.series(:foo, :foo, :foo)).to be_nil
        end

        it "matches series" do
          expect(subject.series(:foo)).to eq [ foo_bar ]
          expect(subject.series(:foo, :foo)).to eq [ foo_bar, foo_baz ]
        end
      end
    end
  end
end
