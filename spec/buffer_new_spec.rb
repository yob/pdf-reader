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
      expect(newtok).to eql(oldtok)

      break if newtok.nil?
    end
  end

  it "returns nil" do
    compare_buffers("aaa")
  end
  it "tokenises correctly" do
    compare_buffers("aaa")
  end
  it "tokenise correctly" do
    compare_buffers("aaa")
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
end
