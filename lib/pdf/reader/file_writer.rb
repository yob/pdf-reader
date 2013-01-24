# coding: utf-8

require 'stringio'

class PDF::Reader
  # Converts an ObjectHash into a PDF file. The results can be returned as a string
  # or written to a file.
  class FileWriter
    def initialize(objects)
      @objects = objects
    end

    def to_s
      io = StringIO.new
      to_io(io)
      str = io.string
      str.force_encoding("binary") if str.respond_to?(:force_encoding)
      str
    end

    def to_io(writer)
      if @objects.has_updates?
        incremental_save_to_io(writer)
      else
        copy_to_io(writer)
      end
    end

    private

    def copy_to_io(writer)
      @objects.io.seek(0)
      writer.write @objects.io.read
    end

    def add_updated_objects(writer)
      # now write the updated objects
      offsets = {}
      @objects.each_updated do |key, value|
        offsets[key] = writer.pos
        writer.write "#{key.id} #{key.gen} obj\n"
        writer.write PdfObject.dump(value)
        writer.write "\r\nendobj\r\n"
      end
      offsets
    end

    def add_traditional_xref(writer, offsets)
      writer.write "xref\r\n"
      each_offset_group(offsets) do |group|
        starts_at = group.keys.sort.first.id
        writer.write("#{starts_at} #{group.size}\r\n")
        group.each do |key, offset|
          writer.write("%010d 00000 n\r\n" % offset)
        end
      end
    end

    def add_traditional_trailer(writer, xref_offset)
      writer.write "trailer\r\n"
      writer.write PdfObject.dump(@objects.trailer) << "\r\n"
      writer.write "startxref\r\n"
      writer.write "#{xref_offset}\r\n"
      writer.write "%%EOF\r\n"
    end

    def add_stream_trailer(writer, xref_offset)
      writer.write "startxref\n"
      writer.write "#{xref_offset}\n"
      writer.write "%%EOF\n"
    end

    def add_stream_xref(writer, offsets)
      xref_offset = writer.pos
      max_id = @objects.keys.sort.last.id
      reference = PDF::Reader::Reference.new(max_id, 0)
      offsets[reference] = xref_offset
      stream_data, index = build_xref_stream_data(offsets)
      dict = @objects.trailer.merge(
        :Type   => :XRef,
        :Length => stream_data.size,
        :Index  => index,
        :W      => [1,4,1],
        :Size   => @objects.keys.sort.last.id+1)
      writer.write "#{max_id} 0 obj\n"
      writer.write PdfObject.dump(dict) << "\n"
      writer.write "stream\n"
      writer.write stream_data + "\n"
      writer.write "endstream\n"
      writer.write "endobj\n"
    end

    def incremental_save_to_io(writer)
      @objects.io.seek(0)
      # write the original PDF
      writer.write @objects.io.read
      writer.write "\n"

      # write the updated and new objects
      offsets     = add_updated_objects(writer)

      # write a new xref table (or stream) and trailer
      xref_offset = writer.pos
      if @objects.traditional_xref? # if traditional xref
        add_traditional_xref(writer, offsets)
        add_traditional_trailer(writer, xref_offset)
      else
        add_stream_xref(writer, offsets)
        add_stream_trailer(writer, xref_offset)
      end
    end

    def build_xref_stream_data(offsets)
      data  = StringIO.new
      index = []
      each_offset_group(offsets) do |group|
        starts_at = group.keys.sort.first.id
        index << starts_at
        index << group.size
        group.each do |key, offset|
          data.write [1, offset, 0].pack("CNC")
        end
      end

      if "".respond_to?(:force_encoding)
        return data.string.force_encoding("binary"), index
      else
        return data.string, index
      end
    end

    def each_offset_group(offsets, &block)
      keys  = offsets.keys.sort
      accum = {}
      keys.each do |key|
        if accum.empty?
          accum[key] = offsets[key]
        elsif accum.keys.sort.last.id == key.id - 1
          accum[key] = offsets[key]
        else
          yield accum
          accum = {key => offsets[key]}
        end
      end
      yield accum unless accum.empty?
    end

  end
end
