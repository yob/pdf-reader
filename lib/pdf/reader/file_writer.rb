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

    def add_updated_objects_and_xref(writer)
      # now write the updated objects
      offsets = {}
      @objects.each_updated do |key, value|
        offsets[key] = writer.pos
        writer.write "#{key.id} #{key.gen} obj\n"
        writer.write PdfObject.dump(value)
        writer.write "\nendobj\n"
      end

      updated_xref_pos = writer.pos
      writer.write "xref\n"
      each_offset_group(offsets) do |group|
        starts_at = group.keys.sort.first.id
        writer.write("#{starts_at} #{group.size}\n")
        group.each do |key, offset|
          writer.write("%010d 00000 n \n" % offset)
        end
      end
      updated_xref_pos
    end

    def add_new_trailer(writer, xref_offset)
      writer.write "trailer\n"
      writer.write PdfObject.dump(@objects.trailer) << "\n"
      writer.write "startxref\n"
      writer.write "#{xref_offset}\n"
      writer.write "%%EOF"
    end

    def incremental_save_to_io(writer)
      @objects.io.seek(0)
      # write the original PDF
      writer.write @objects.io.read
      writer.write "\n"

      xref_offset = add_updated_objects_and_xref(writer)
      add_new_trailer(writer, xref_offset)
    end

    private

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
