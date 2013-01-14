# coding: utf-8

require 'forwardable'

class PDF::Reader
  # Provides low level access to the objects in a PDF file via a hash-like
  # object.
  #
  # A PDF file can be viewed as a large hash map. It is a series of objects
  # stored at precise byte offsets, and a table that maps object IDs to byte
  # offsets. Given an object ID, looking up an object is an O(1) operation.
  #
  # Each PDF object can be mapped to a ruby object, so by passing an object
  # ID to the [] method, a ruby representation of that object will be
  # retrieved.
  #
  # The class behaves much like a standard Ruby hash, including the use of
  # the Enumerable mixin. The key difference is no []= method - the hash
  # is read only.
  #
  # == Basic Usage
  #
  #     h = PDF::Reader::ObjectHash.new("somefile.pdf")
  #     h[1]
  #     => 3469
  #
  #     h[PDF::Reader::Reference.new(1,0)]
  #     => 3469
  #
  class ObjectHash
    extend Forwardable
    include Enumerable

    def_delegators :@objects, :pdf_version, :trailer
    def_delegators :@objects, :obj_type, :stream?, :[], :object, :deref, :deref!
    def_delegators :@objects, :fetch, :each, :each_pair, :each_key, :each_value
    def_delegators :@objects, :size, :length, :has_key?, :include?, :key?, :empty?
    def_delegators :@objects, :member?, :value?, :has_value?, :keys, :values
    def_delegators :@objects, :values_at, :page_references
    def_delegators :encrypted?, :sec_handler?

    def initialize(input, opts = {})
      @io       = extract_io_from(input)
      @pos_orig_xref = PDF::Reader::Buffer.new(@io).find_first_xref_offset
      @objects  = PDF::Reader::FileHash.new(@io, opts)
      @updated  = {}
    end

    def []=(key, value)
      unless key.is_a?(PDF::Reader::Reference)
        key = PDF::Reader::Reference.new(key.to_i, 0)
      end
      @updated[key] = value
    end

    def save(writer)
      @io.seek(0)
      # write the original PDF
      writer.write @io.read
      writer.write "\n"

      # now write the updated objects
      offsets = {}
      @updated.each do |key, value|
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
      writer.write PdfObject.dump(new_trailer) << "\n"
      writer.write "startxref\n"
      writer.write "#{updated_xref_pos}\n"
      writer.write "%%EOF"
    end

    private

    def new_trailer
      # deep copy the original trailer
      dict = Marshal.load(Marshal.dump(@objects.trailer))
      # and add a pointer to the previous xref table
      dict[:Prev] = @pos_orig_xref
      dict
    end

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

    def extract_io_from(input)
      if input.respond_to?(:seek) && input.respond_to?(:read)
        input
      elsif File.file?(input.to_s)
        StringIO.new read_as_binary(input)
      else
        raise ArgumentError, "input must be an IO-like object or a filename"
      end
    end

    def read_as_binary(input)
      if File.respond_to?(:binread)
        File.binread(input.to_s)
      else
        File.open(input.to_s,"rb") { |f| f.read }
      end
    end
  end
end
