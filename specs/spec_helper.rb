# coding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'
require 'timeout'
require 'singleton'

class Array
  def to_h
    Hash[*self.flatten]
  end
end

module BufferHelper
  def parse_string (r)
    PDF::Reader::Buffer.new(StringIO.new(r))
  end
end

module ParserHelper
  def parse_string (r)
    buf = PDF::Reader::Buffer.new(StringIO.new(r))
    PDF::Reader::Parser.new(buf, nil)
  end
end

class CallbackHelper
  include Singleton

  def good_receivers
    @registers ||= {}
    if @registers.empty?
      good_files.map { |filename|
        receiver = PDF::Reader::RegisterReceiver.new
        PDF::Reader.file(filename, receiver)
        @registers[filename] = receiver
      }
    end
    @registers
  end

  private

  def good_files
    @good_files ||= Dir.glob(File.dirname(__FILE__) + "/data/*.pdf").select { |filename|
      !filename.include?("screwey_xref_offsets") &&
        !filename.include?("difference_table_encrypted") &&
        !filename.include?("broken_string.pdf") &&
        !filename.include?("cross_ref_stream.pdf") &&
        !filename.include?("zlib_stream_issue.pdf") &&
        !filename.include?("20070313")
    }
  end

end

module EncodingHelper
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
      obj.encoding.should   eql(Encoding.find("utf-8"))
      obj.valid_encoding?.should   be_true
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
      obj.each { |item| check_utf8(item) }
    when Hash
      obj.each { |key, value|
        check_utf8(key)
        check_utf8(value)
      }
    when String
      obj.encoding.should   eql(Encoding.find("binary"))
      obj.valid_encoding?.should   be_true
    else
      return
    end
  end
end
