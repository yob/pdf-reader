module Zlib
ZLIBY_VERSION = "0.0.2"
ZLIB_VERSION = "1.2.3"	
VERSION = "0.6.0" #For compatibility with Ruby-core Zlib
MAXBITS = 15
MAXLCODES = 286
MAXDCODES = 30
MAXCODES = (MAXLCODES+MAXDCODES) 
FIXLCODES = 288     
MAX_WBITS = 15
Z_DEFLATED = 8 


class ZStream
	
	def initialize
		@input_buffer = []
		@output_buffer = []
		@out_pos = -1
		@in_pos = -1
		@bit_bucket = 0
		@bit_count = 0

	end
	#Returns the adler-32 checksum of the input data.
	def adler
	end
	
	#Returns the number of bytes read. Normally 0 since all bytes are read at once.
	def avail_in
		@input_buffer.length - @in_pos
	end
	
	#Returns number of free bytes in the output buffer.  As the output buffer is self expanding this normally returns 0.
	def avail_out
		@output_buffer.length - @out_pos
	end
	
	#Allocates size bytes in output buffer.  If size < avail_out it truncates the buffer.
	def avail_out= size
		size.times do 
			if size > avail_out
				@output_buffer.push nil
			else
				@output_buffer.pop
			end
		end
	end
	
	#Closes stream.  Further operations will raise Zlib::StreamError
	def close
		@closed = true
	end
	
	#True if stream closed, otherwise False.
	def closed?
		@closed
	end
	
	#Best guess of input data, one of Zlib::BINARY, Zlib::ASCII, or Zlib::UNKNOWN
	def data_type
	end
	
	#See close
	def end
		close
	end
	
	#See closed?
	def ended?
		closed?
	end
	
	#Finishes the stream, flushes output buffer, implemented by child classes
	def finish
		close
	end
	
	#True if stream is finished, otherwise False
	def finished?
	end
	
	#Flushes input buffer and returns the data therein.
	def flush_next_in
		@in_pos = @input_buffer.length
		@input_buffer
	end
	
	#Flushes the output buffer and returns all the data
	def flush_next_out
		@out_pos = @output_buffer.length
		@output_buffer
	end
	
	#Reset stream.  Input and Output buffers are reset.
	def reset
		@out_pos = -1
		@in_pos = -1
		@input_buffer = []
		@output_buffer = []
	end
	
	#See finished.
	def stream_end?
		finished?
	end
	
	#Size of input buffer.
	def total_in
		@input_buffer.length
	end
	
	#Size of output buffer.
	def total_out
		@output_buffer.length
	end
	
	private
	#returns need bits from the input buffer
	# == Format Notes
	# bits are stored LSB to MSB 
	def get_bits need
		val = @bit_bucket
		while @bit_count < need
			val |= (@input_buffer[@in_pos+=1] << @bit_count)
			@bit_count += 8
		end
		
		@bit_bucket = val >> need
		@bit_count -= need
		val & ((1 << need) - 1)
	end
public	
end

#== DEFLATE Decompression
#Implements decompression of a RFC-1951[ftp://ftp.rfc-editor.org/in-notes/rfc1951.txt] compatible stream.
class Inflate < ZStream
	def initialize window_bits=MAX_WBITS
		@w_bits = window_bits	
		if @w_bits < 0 then 
			@rawdeflate = true
			@w_bits *= -1 
		end	
		super()
	end
	
	#==Example
	# f = File.open "example.z"
	# i = Inflate.new
	# i.inflate f.read
	def inflate zstring
		
		#We can't use unpack, IronRuby doesn't have it yet.
		@input_buffer = zstring.unpack("C*")
		
	 	unless @rawdeflate then

		compression_method_and_flags = @input_buffer[@in_pos+=1]
		flags = @input_buffer[@in_pos+=1]
		
		#CMF and FLG, when viewed as a 16-bit unsigned integer stored inMSB order (CMF*256 + FLG), is a multiple of 31
		if ((compression_method_and_flags << 0x08) + flags) % 31 != 0 then raise Zlib::DataError.new("incorrect header check") end
		
		#CM = 8 denotes the ?deflate? compression method with a window size up to 32K. (RFC's only specify CM 8)
		compression_method = compression_method_and_flags & 0x0F 
		
		if compression_method != Z_DEFLATED then raise Zlib::DataError.new("unknown compression method") end
		
		#For CM = 8, CINFO is the base-2 logarithm of the LZ77 window size,minus eight (CINFO=7 indicates a 32K window size)
		compression_info = compression_method_and_flags >> 0x04 
		
		if (compression_info + 8) > @w_bits then raise Zlib::DataError.new("invalid window size") end
		
		preset_dictionary_flag = ((flags & 0x20) >> 0x05) == 1
		compression_level = (flags & 0xC0) >> 0x06
		
		#TODO:  Add Preset dictionary support
		if preset_dictionary_flag then @in_pos += 4 end
		
		end
		last_block = false
		#Begin processing DEFLATE stream
		until last_block
			last_block = (get_bits(1) == 1)
			block_type = get_bits(2)
			case block_type
				when 0 then no_compression
				when 1 then fixed_codes
				when 2 then dynamic_codes
 				when 3 then raise Zlib::DataError.new("invalid block type")	 
			end	
		end
		finish
	end
	
	#Finishes inflating and flushes the buffer
	def finish
		output = ""
		@output_buffer.each {|c| output << c }
		super
		output
	end
	
	private

	def no_compression
		@bit_bucket = 0
		@bit_count = 0
		if @in_pos + 4 > @input_buffer.length then raise Zlib::DataError.new("not enough input to read length code") end
		length = @input_buffer[@in_pos+=1] | (@input_buffer[@in_pos+=1] << 8)
			
		if (~length & 0xff != @input_buffer[@in_pos+=1]) || (((~length >> 8) & 0xff) != @input_buffer[@in_pos+=1]) then raise Zlib::DataError.new("invalid stored block lengths") end
		
		if @in_pos + length > @input_buffer.length then raise Zlib::DataError.new("ran out of input") end
				
		
		length.times do
			@output_buffer[@out_pos += 1] = @input_buffer[@in_pos += 1]
		end
		   	
			
	end
	
	def fixed_codes
		if @fixed_length_codes.nil? && @fixed_distance_codes.nil? then generate_huffmans end 
		codes @fixed_length_codes, @fixed_distance_codes	
	end
	
	def dynamic_codes
		
		order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
		nlen = get_bits(5) + 257
		ndist = get_bits(5) + 1
		ncode = get_bits(4) + 4

				
		lengths=[]
		dynamic_length_codes = Zlib::Inflate::HuffmanTree.new
		dynamic_distance_codes = Zlib::Inflate::HuffmanTree.new
		
		if (nlen > MAXLCODES || ndist > MAXDCODES) then raise Zlib::DataError.new("too many length or distance codes") end
		idx = 0
		
		while idx < ncode
			lengths[order[idx]] = get_bits(3)
			idx += 1
		end
		while idx < 19
			lengths[order[idx]] = 0
			idx += 1
		end
		err = construct_tree dynamic_length_codes, lengths, 18
		if err != 0 then raise Zlib::DataError.new("code lengths codes incomplete") end
		
		idx = 0
		while idx < (nlen + ndist)
			symbol = decode(dynamic_length_codes)
			if symbol < 16 then 
				lengths[idx] = symbol 
				idx  += 1;
			else
				len = 0
					if symbol == 16 then 
						if idx == 0 then raise Zlib::DataError.new("repeat lengths with no first length") end
						len = lengths[idx - 1]
						symbol = 3 + get_bits(2)
					elsif symbol == 17 then
						symbol = 3 + get_bits(3)
					elsif symbol == 18 then 
						symbol = 11 + get_bits(7)
					else
						raise Zlib::DataError.new("invalid repeat length code")
					end
				if (idx + symbol) > (nlen + ndist) then raise Zlib::DataError.new("repeat more than specified lengths") end
				until symbol == 0
					lengths[idx] = len
					idx+=1
					symbol -= 1
				end
			end
		end

		err = construct_tree dynamic_length_codes, lengths, nlen-1
		
		if err < 0 || (err > 0 && (nlen - dynamic_length_codes.count[0] != 1)) then raise Zlib::DataError.new("invalid literal/length code lengths") end
		
		nlen.times { lengths.delete_at 0 } #We do this since we don't have pointer arithmetic in ruby
		
		err = construct_tree dynamic_distance_codes, lengths, ndist-1
		if err < 0 || (err > 0 && (ndist - dynamic_distance_codes.count[0] != 1)) then raise Zlib::DataError.new("invalid distance code lengths") end
			
		codes dynamic_length_codes, dynamic_distance_codes
	end
	
	def generate_huffmans
		
		lengths = []
		
		#literal/length table
		for idx in (000..143)
			lengths[idx] = 8
		end
		for idx in (144..255) 
			lengths[idx] = 9
		end
		for idx in (256..279)
			lengths[idx] = 7
		end
		for idx in (280..287)
			lengths[idx] = 8
		end
			@fixed_length_codes = Zlib::Inflate::HuffmanTree.new
			construct_tree @fixed_length_codes, lengths, 287
		
		for idx in (00..29)
			lengths[idx] = 5
		end
			@fixed_distance_codes = Zlib::Inflate::HuffmanTree.new
			construct_tree @fixed_distance_codes, lengths, 29
		
	end
	
	def codes length_codes, distance_codes
	lens = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258]
	lext = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
	dists = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577]
	dext = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]
	
	symbol = 0
	
	until symbol == 256
		symbol = decode(length_codes)
		if symbol < 0 then return symbol end
		if symbol < 256 then @output_buffer[@out_pos+=1] = symbol end
		if symbol > 256 then
			symbol -= 257
			if symbol >= 29 then raise Zlib::DataError.new("invalid literal/length or distance code in fixed or dynamic block") end
			len = lens[symbol] + get_bits(lext[symbol])
			symbol = decode(distance_codes)
			if symbol < 0 then return symbol end
			dist = dists[symbol] + get_bits(dext[symbol])
			if dist > @output_buffer.length then raise Zlib::DataError.new("distance is too far back in fixed or dynamic block") end
			while len > 0
				@output_buffer[@out_pos+=1] = @output_buffer[@out_pos - dist]
				len -= 1
			end
	end
	end
	return 0
	end
	
	def decode huffman_tree
		code = 0
		first = 0
		index = 0 
		for len in (1..15)
			code |= get_bits(1)
			count = huffman_tree.count[len]
			if code < (first + count) then return huffman_tree.symbol[index + (code - first)] end
			index += count
			first += count
			first <<= 1
			code <<= 1
		end
		-9
	end
	
	def construct_tree huffman_tree, lengths, n_symbols
		offs = []
		
		
		for len in (000..MAXBITS)
			huffman_tree.count[len] = 0
		end

		for symbol in (000..n_symbols)
			huffman_tree.count[lengths[symbol]] += 1
		end
		
		
		if huffman_tree.count[0] == n_symbols then return 0 end
		
		left = 1
		for len in (1..MAXBITS)
			left <<= 1
			left -= huffman_tree.count[len];
			if left < 0 then return left end
		end
		
		offs[1] = 0
		
		for len in (1..(MAXBITS-1))
			offs[len+1] = offs[len] + huffman_tree.count[len]
		end
		
		for symbol in (0..n_symbols)
			if lengths[symbol] != 0 then 
				huffman_tree.symbol[offs[lengths[symbol]]] = symbol 
				offs[lengths[symbol]] += 1
				end
			
		end
	left
	end

class HuffmanTree
	attr_accessor :count, :symbol
	def initialize
		@count = []
		@symbol = []
	end
end

	class << self
		def inflate zstring
			d = self.new
			d.inflate zstring
		end
	end

end


class GzipFile
	
	def initialize
		@input_buffer = []
		@output_buffer = []
		@out_pos = -1
		@in_pos = -1
	end
	
	def close
	end
	
	class Error < Exception
	end

end

class GzipReader < GzipFile
	OSES = ['FAT filesystem', 
			'Amiga', 
			'VMS (or OpenVMS)', 
			'Unix', 
			'VM/CMS', 
			'Atari TOS', 
			'HPFS fileystem (OS/2, NT)', 
			'Macintosh', 
			'Z-System',
			'CP/M',
			'TOPS-20',
			'NTFS filesystem (NT)',
			'QDOS',
			'Acorn RISCOS',
			'unknown']
	def initialize io
		super()
		@io = io
		io.read.each_byte {|b| @input_buffer << b}
		if @input_buffer[@in_pos+=1] != 0x1f || @input_buffer[@in_pos+=1] != 0x8b then raise Zlib::GzipFile::Error.new("not in gzip format") end
		if @input_buffer[@in_pos+=1] != 0x08 then raise Zlib::GzipFile::Error.new("unknown compression method") end
		flg = @input_buffer[@in_pos+=1]
		@ftext = flg.isbitset? 0
		@fhcrc = flg.isbitset? 1
		@fextra = flg.isbitset? 2
		@fname = flg.isbitset? 3
		@fcomment = flg.isbitset? 4
		@mtime = Time.at(@input_buffer[@in_pos+=1] | (@input_buffer[@in_pos+=1] << 8) | (@input_buffer[@in_pos+=1] << 16) | (@input_buffer[@in_pos+=1] << 24))
		@xfl = @input_buffer[@in_pos+=1]
		@os = OSES[@input_buffer[@in_pos+=1]]
		if @fextra then 
			@xlen = (@input_buffer[@in_pos+=1] | (@input_buffer[@in_pos+=1] << 8)) 
			@xtra_field = []
			@xlen.times {@xtra_field << @input_buffer[@in_pos+=1]}
		end
		if @fname then
			@original_name = ""
			until @original_name["\0"].nil? == false
				@original_name.concat(@input_buffer[@in_pos+=1])
			end
			@original_name.chop!
		end
		if @fcomment then
			@comment = ""
			until @comment["\0"].nil? == false
				@comment.concat(@input_buffer[@in_pos+=1])
			end
			@comment.chop!
		end
		if @fhcrc then
			@header_crc = @input_buffer[@in_pos+=1] | (@input_buffer[@in_pos+=1] << 8)
		end	
		@contents = ""
		until @in_pos == @input_buffer.length-1
			@contents.concat(@input_buffer[@in_pos+=1])
		end
		 
	end
	
	def read
		#we do raw deflate, no headers
		z = Zlib::Inflate.new -MAX_WBITS
		z.inflate @contents
	end
	
	def close
	end

	class << self

		def open filename
			io = File.open filename
			gz = self.new io
			if block_given? then yield gz else gz end
		end
		
	end
end


#Generic Error
class Error < Exception
end

#Dictionary Needed
class NeedDict < Error
end

#Invalid Data
class DataError < Error
end

end

#Add a helper method to check bits
class Fixnum
	def isbitset? bit_to_check
		if self & (2 ** bit_to_check)  == (2 ** bit_to_check) then true else false end
	end
end
