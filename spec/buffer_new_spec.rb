# typed: false
# coding: utf-8

describe PDF::Reader::BufferNew, "token method" do
  include BufferHelper

  def compare_buffers(input)
    buf = parse_string(input)
    bufnew = parse_string2(input)

    loop do
      newtok = bufnew.token
      oldtok = buf.token
      #puts "newtok: #{newtok}"
      expect(newtok).to eql(oldtok)

      break if newtok.nil?
    end
  end

  def compare_buffers_with_offset(input, seek)
    buf = PDF::Reader::Buffer.new(StringIO.new(input), :seek => seek)
    bufnew = PDF::Reader::BufferNew.new(StringIO.new(input), :seek => seek)

    loop do
      newtok = bufnew.token
      oldtok = buf.token
      #puts "newtok: #{newtok}"
      expect(newtok).to eql(oldtok)

      break if newtok.nil?
    end
  end

  it "tokenises correctly" do
    compare_buffers("aaa")
  end
  it "tokenises correctly" do
    compare_buffers("aaa")
  end
  it "tokenises correctly" do
    compare_buffers("1.2")
  end
  it "tokenise correctly" do
    compare_buffers("aaa")
  end
  it "tokenise correctly" do
    compare_buffers("[aaa]")
  end
  it "tokenise correctly" do
    compare_buffers("(aaa)")
  end
  it "tokenise correctly" do
    compare_buffers("<aaa>")
  end
  it "tokenise correctly" do
    compare_buffers("<aaa><bbb>")
  end
  it "tokenise correctly" do
    compare_buffers("<<aaa>>")
  end
  it "tokenise correctly" do
    compare_buffers("/Type/Pages")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon-Hyphened")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon,Comma")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon+Plus")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon*Star")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon_Underscore")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon:Colon")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon;SemiColon")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon'Apos")
  end
  it "tokenise correctly" do
    compare_buffers("/Chunky/Bacon\\\\escaped-slash")
  end
  #it "tokenise correctly" do
  #  compare_buffers("/ /")
  #end
  #it "tokenise correctly" do
  #  compare_buffers("<</V/>>")
  #end
  it "tokenise correctly" do
    compare_buffers("/Type/Pages")
  end
  it "tokenise correctly" do
    compare_buffers("/Registry (Adobe) /Ordering (Japan1) /Supplement")
  end
  it "tokenise correctly" do
    compare_buffers("(James%Healy)")
  end
  it "tokenise correctly" do
    compare_buffers("<AA BB>")
  end
  it "tokenise correctly" do
    compare_buffers("(James%Healy) % this is a comment\n(")
  end
  it "tokenise correctly" do
    compare_buffers("James % this is a comment")
  end
  #it "tokenise correctly" do
  #  compare_buffers("(James \\(Code Monkey)")
  #end
  #it "tokenise correctly" do
  #  compare_buffers("(James Code Monkey\\))")
  #end
  it "tokenise correctly" do
    compare_buffers("aaa 1 0 R bbb")
  end
  it "tokenise correctly" do
    compare_buffers("1 0 R 2 0 R")
  end
  it "tokenise correctly" do
    compare_buffers_with_offset("aaa bbb ccc", 4)
  end
  it "tokenise correctly" do
    compare_buffers_with_offset("aaa bbb ccc", 5)
  end
  it "tokenise correctly" do
    compare_buffers("(aaa)")
  end
  it "tokenise correctly" do
    compare_buffers("()")
  end
  it "tokenise correctly" do
    compare_buffers("(aaa bbb)")
  end
  it "tokenise correctly" do
    compare_buffers("(aaa (bbb))")
  end
  it "tokenise correctly" do
    input = "(aaa (bbb))"
    bufnew = parse_string2(input)

    expect(bufnew.token).to eq("(")
    expect(bufnew.token).to eq("aaa (bbb)")
    expect(bufnew.token).to eq(")")
  end
  it "tokenise correctly" do
    input = "(aaa\x5c\x0a bbb)"
    bufnew = parse_string2(input)

    expect(bufnew.token).to eq("(")
    expect(bufnew.token).to eq("aaa\x5c\x0a bbb")
    expect(bufnew.token).to eq(")")
  end
  it "tokenise correctly" do
    compare_buffers("(aaa\x5C\x5C)")
  end
  it "tokenise correctly" do
    compare_buffers("(aaa\x5C\x0D\x0Abbb)")
  end
  it "tokenise correctly" do
    input = "(aaa\x5C\x5C)"
    bufnew = parse_string2(input)

    expect(bufnew.token).to eq("(")
    expect(bufnew.token).to eq("aaa\x5C\x5C")
    expect(bufnew.token).to eq(")")
  end
  it "tokenise correctly" do
    compare_buffers("<< /X <48656C6C6F> >>")
  end
  #it "tokenise correctly" do
  #  compare_buffers("/Span<</ActualText<FEFF0009>>> BDC")
  #end
  it "tokenise correctly" do
    compare_buffers("<< /X 10 0 R >>")
  end
  it "tokenise correctly" do
    compare_buffers("<< /X 10 0 R /Y 11 0 R /Z 12 0 R >>")
  end

  # when the stream data length disagrees with the Length value of he dict, which should we use?
  # The old buffer trusts the Length value, the new buffer currently lexes until it finds the end of the stream
  it "tokenise correctly" do
    stream = <<~EOS
2 0 obj
<< /Length 4
   /Type /Test
>>
stream
1234 Tj
endstream
enobj
EOS
    compare_buffers(stream)
  end

end
