require 'lib/pdf/reader/lzw'

class LZWTest < Test::Unit::TestCase

  def test_string
    content = '80 0B 60 50 22 0C 0C 85 01'.split(' ').map { |byte| byte .to_i(16)}
    assert_equal '-----A---B', LZW::decode(content)
  end
  
end
