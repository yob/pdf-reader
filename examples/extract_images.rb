# coding: utf-8

# This demonstrates a way to extract some images (those based on the JPG or
# TIFF formats) from a PDF. There are other ways to store images, so 
# it may need to be expanded for real world usage, but it should serve
# as a good guide.
#
# Thanks to Jack Rusher for the initial version of this example.

require 'pdf/reader'

module ExtractImages

  class Extractor

    def page(page)
      count = 0
      page.xobjects.each do |name, stream|
        stream = page.objects.deref(stream)

        next unless stream.hash[:Subtype] == :Image

        count += 1

        case stream.hash[:Filter]
        when :CCITTFaxDecode
          ExtractImages::Tiff.new(stream).save("#{page.number}-#{count}-#{name}.tif")
        when :DCTDecode
          ExtractImages::Jpg.new(stream).save("#{page.number}-#{count}-#{name}.jpg")
        else
          $stderr.puts "unrecognized image filter '#{stream.hash[:Filter]}'!"
        end
      end
    end

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

filename = File.expand_path(File.dirname(__FILE__)) + "/../spec/data/adobe_sample.pdf"
extractor = ExtractImages::Extractor.new

PDF::Reader.open(filename) do |reader|
  page = reader.page(1)
  extractor.page(page)
end
