# coding: utf-8

# This demonstrates a way to extract some images (those based on the JPG or
# TIFF formats) from a PDF. There are other ways to store images, so 
# it may need to be expanded for real world usage, but it should serve
# as a good guide.
#
# Thanks to Jack Rusher for the initial version of this example.
#
# USAGE:
#
#   ruby extract_images.rb somefile.pdf

require 'pdf/reader'

module ExtractImages

  class Receiver
    attr_reader :count

    def initialize
      @count = 0
    end

    def resource_xobject(name, stream)
      return unless stream.hash[:Subtype] == :Image
      increment_count

      case stream.hash[:Filter]
      when :CCITTFaxDecode
        ExtractImages::Tiff.new(stream).save("#{count}-#{name}.tif")
      when :DCTDecode
        ExtractImages::Jpg.new(stream).save("#{count}-#{name}.jpg")
      else
        $stderr.puts "unrecognized image filter '#{stream.hash[:Filter]}'!"
      end
    end

    def increment_count
      @count += 1
    end
    private :increment_count

  end

  class Jpg
    attr_reader :stream

    def initialize(stream)
      @stream = stream
    end

    def save(filename)
      w = stream.hash[:Width]
      h = stream.hash[:Height]
      puts "#{filename}: h=#{h}, w=#{w}"
      File.open(filename, "wb") { |file| file.write stream.data }
    end
  end

  class Tiff
    attr_reader :stream

    def initialize(stream)
      @stream = stream
    end

    def save(filename)
      if stream.hash[:DecodeParms][:K] <= 0
        save_group_four(filename)
      else
        $stderr.puts "#{filename}: CCITT non-group 4/2D image."
      end
    end

    private

    # Group 4, 2D
    def save_group_four(filename)
      k    = stream.hash[:DecodeParms][:K]
      h    = stream.hash[:Height]
      w    = stream.hash[:Width]
      bpc  = stream.hash[:BitsPerComponent]
      mask = stream.hash[:ImageMask]
      len  = stream.hash[:Length]
      cols = stream.hash[:DecodeParms][:Columns]
      puts "#{filename}: h=#{h}, w=#{w}, bpc=#{bpc}, mask=#{mask}, len=#{len}, cols=#{cols}, k=#{k}"

      # Synthesize a TIFF header
      long_tag  = lambda {|tag, value| [ tag, 4, 1, value ].pack( "ssII" ) }
      short_tag = lambda {|tag, value| [ tag, 3, 1, value ].pack( "ssII" ) }
      # header = byte order, version magic, offset of directory, directory count,
      # followed by a series of tags containing metadata: 259 is a magic number for
      # the compression type; 273 is the offset of the image data.
      tiff = [ 73, 73, 42, 8, 5 ].pack("ccsIs") \
      + short_tag.call( 256, cols ) \
      + short_tag.call( 257, h ) \
      + short_tag.call( 259, 4 ) \
      + long_tag.call( 273, (10 + (5*12)) ) \
      + long_tag.call( 279, len) \
      + stream.data
      File.open(filename, "wb") { |file| file.write tiff }
    end
  end
end

receiver = ExtractImages::Receiver.new
PDF::Reader.file(ARGV[0], receiver)
