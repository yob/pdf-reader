# typed: false
# coding: utf-8

describe PDF::Reader::Filter::Depredict do
  describe "#filter" do
    context "a stream with PNG predictors" do
      it "depredicts every row of a large stream in linear time" do
        # 400k scanlines shaped like the xref stream in
        # https://github.com/yob/pdf-reader/issues/614. The old
        # implementation needed minutes here; linear time is seconds.
        rows = 400_000
        data = ("\x02".b + "\x00".b * 7) * rows
        Timeout::timeout(60) do
          filter = PDF::Reader::Filter::Depredict.new(
            :Columns => 7,
            :Predictor => 12
          )
          expect(filter.filter(data)).to eql("\x00".b * 7 * rows)
        end
      end
    end
  end
end
