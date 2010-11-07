#ref http://www.fileformat.info/format/tiff/corion-lzw.htm
#ref http://marknelson.us/1989/10/01/lzw-data-compression/
#
class LZW

  class BitStream

    def initialize(data, bits_in_chunk)
      @data = data
      @bits_in_chunk = bits_in_chunk
      @current_pos = 0
      @bits_left_in_byte = 8
    end

    def set_bits_in_chunk(bits_in_chunk)
      @bits_in_chunk = bits_in_chunk
    end

    def read
      bits_left_in_chunk = @bits_in_chunk
      chunk = nil
      while bits_left_in_chunk > 0 and @current_pos < @data.size
        chunk = 0 if chunk.nil?
        current_byte = @data[@current_pos] & (2**@bits_left_in_byte -1) #clear consumed bits
        dif = bits_left_in_chunk - @bits_left_in_byte
        if dif > 0 then  current_byte <<= dif
        elsif dif < 0 then  current_byte >>= dif.abs
        end
        chunk |= current_byte #add bits to result
        bits_left_in_chunk = if dif >= 0 then dif else 0 end
        @bits_left_in_byte = if dif < 0 then dif.abs else 0 end
        if @bits_left_in_byte.zero? #next byte
          @current_pos += 1
          @bits_left_in_byte = 8
        end
      end
      chunk
    end
  end

  CODE_EOD = 257 #end of data
  CODE_CLEAR_TABLE = 256 #clear table

  #stores de pairs code => string
  class StringTable < Hash
    attr_reader :string_table_pos

    def initialize
      super
      @string_table_pos = 258 #initial code
    end

    #if code less than 258 return fixed string
    def [](key)
      if key > 257 then super else key.chr end
    end

    def add(string)
      store(@string_table_pos, string)
      @string_table_pos += 1
    end
  end

  def self.decode(data)
    stream = BitStream.new data, 9 # size of codes between 9 and 12 bits
    result = ''
    while not (code = stream.read) == CODE_EOD
      if code == CODE_CLEAR_TABLE
        string_table = StringTable.new
        code = stream.read
        break if code == CODE_EOD
        result << string_table[code]
        old_code = code
      else
        string = string_table[code]
        if string
          result << string
          string_table.add create_new_string(string_table, old_code, code)
          old_code = code
        else
          new_string = create_new_string(string_table, old_code, old_code)
          result << new_string
          string_table.add new_string
          old_code = code
        end
        #increase de size of the codes when limit reached
        case string_table.string_table_pos
          when 511 then stream.set_bits_in_chunk(10)
          when 1023 then stream.set_bits_in_chunk(11)
          when 2047 then stream.set_bits_in_chunk(12)
        end
      end
    end
    result
  end

  private
  def self.create_new_string(string_table,some_code, other_code)
    string_table[some_code] + string_table[other_code][0].chr
  end

end

