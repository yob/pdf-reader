# coding: utf-8

module EncodingHelper
  def binary_string(str)
    str = str.force_encoding("binary") if str.respond_to?(:force_encoding)
    str
  end

  # On M17N aware VMs, recursively checks strings and containers with strings
  # to ensure everything is UTF-8 encoded
  #
  def check_utf8(obj)
    return unless RUBY_VERSION >= "1.9"

    case obj
    when Array
      obj.each { |item| check_utf8(item) }
    when Hash
      obj.each { |key, value|
        check_utf8(key)
        check_utf8(value)
      }
    when String
      expect(obj.encoding).to eq Encoding.find("utf-8")
      expect(obj.valid_encoding?).to eq true
    else
      return
    end
  end

  # On M17N aware VMs, recursively checks strings and containers with strings
  # to ensure everything is Binary encoded
  #
  def check_binary(obj)
    return unless RUBY_VERSION >= "1.9"

    case obj
    when Array
      obj.each { |item| check_binary(item) }
    when Hash
      obj.each { |key, value|
        check_binary(key)
        check_binary(value)
      }
    when String
      expect(obj.encoding).to eq Encoding.find("binary")
      expect(obj.valid_encoding?).to eq true
    else
      return
    end
  end
end
