# coding: utf-8

require 'stringio'

class PDF::Reader
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

    def incremental_save_to_io(writer)
      @objects.io.seek(0)
      # write the original PDF
      writer.write @objects.io.read
      writer.write "\n"

      # now write the updated objects
      offsets = {}
      @objects.each_updated do |key, value|
        offsets[key] = writer.pos
        writer.write "#{key.id} #{key.gen} obj\n"
        writer.write PdfObject.dump(value)
        writer.write "\nendobj\n"
      end

      # now the updated footer
      updated_xref_pos = writer.pos
      writer.write "xref\n"
      each_offset_group(offsets) do |group|
        starts_at = group.keys.sort_by(&:id).first.id
        writer.write("#{starts_at} #{group.size}\n")
        group.each do |key, offset|
          writer.write("%010d 00000 n \n" % offset)
        end
      end
      writer.write "trailer\n"
      writer.write PdfObject.dump(@objects.trailer) << "\n"
      writer.write "startxref\n"
      writer.write "#{updated_xref_pos}\n"
      writer.write "%%EOF"
    end

    private

    def each_offset_group(offsets, &block)
      keys  = offsets.keys.sort_by(&:id)
      accum = {}
      keys.each do |key|
        if accum.empty?
          accum[key] = offsets[key]
        elsif accum.keys.sort_by(&:id).last.id == key.id - 1
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
