# coding: utf-8
# typed: true
# frozen_string_literal: true

require 'tempfile'

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
    include Enumerable

    attr_accessor :default
    attr_reader :trailer, :pdf_version
    attr_reader :sec_handler

    # Creates a new ObjectHash object. Input can be a string with a valid filename
    # or an IO-like object.
    #
    # Valid options:
    #
    #   :password - the user password to decrypt the source PDF
    #
    def initialize(input, opts = {})
      @io          = extract_io_from(input)
      @xref        = PDF::Reader::XRef.new(@io)
      @pdf_version = read_version
      @trailer     = @xref.trailer
      @cache       = opts[:cache] || PDF::Reader::ObjectCache.new
      @sec_handler = NullSecurityHandler.new
      @sec_handler = SecurityHandlerFactory.build(
        deref(trailer[:Encrypt]),
        deref(trailer[:ID]),
        opts[:password]
      )
    end

    # returns the type of object a ref points to
    def obj_type(ref)
      self[ref].class.to_s.to_sym
    rescue
      nil
    end

    # returns true if the supplied references points to an object with a stream
    def stream?(ref)
      self.has_key?(ref) && self[ref].is_a?(PDF::Reader::Stream)
    end

    # Access an object from the PDF. key can be an int or a PDF::Reader::Reference
    # object.
    #
    # If an int is used, the object with that ID and a generation number of 0 will
    # be returned.
    #
    # If a PDF::Reader::Reference object is used the exact ID and generation number
    # can be specified.
    #
    def [](key)
      return default if key.to_i <= 0

      unless key.is_a?(PDF::Reader::Reference)
        key = PDF::Reader::Reference.new(key.to_i, 0)
      end

      @cache[key] ||= fetch_object(key) || fetch_object_stream(key)
    rescue InvalidObjectError
      return default
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    def object(key)
      key.is_a?(PDF::Reader::Reference) ? self[key] : key
    end
    alias :deref :object

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return an Array or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting an Array and no other type will do.
    def deref_array(key)
      obj = deref(key)

      return obj if obj.nil?

      obj.tap { |obj|
        raise MalformedPDFError, "expected object to be an Array or nil" if !obj.is_a?(Array)
      }
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return an Array of Numerics or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting an Array and no other type will do.
    #
    # Some effort to cast array elements to a number is made for any non-numeric elements.
    def deref_array_of_numbers(key)
      arr = deref(key)

      return arr if arr.nil?

      raise MalformedPDFError, "expected object to be an Array" unless arr.is_a?(Array)

      arr.map { |item|
        if item.is_a?(Numeric)
          item
        elsif item.respond_to?(:to_f)
          item.to_f
        elsif item.respond_to?(:to_i)
          item.to_i
        else
          raise MalformedPDFError, "expected object to be a number"
        end
      }
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a Hash or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting an Array and no other type will do.
    def deref_hash(key)
      obj = deref(key)

      return obj if obj.nil?

      obj.tap { |obj|
        raise MalformedPDFError, "expected object to be a Hash or nil" if !obj.is_a?(Hash)
      }
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a PDF name (Symbol) or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting an Array and no other type will do.
    #
    # Some effort to cast to a symbol is made when the reference points to a non-symbol.
    def deref_name(key)
      obj = deref(key)

      return obj if obj.nil?

      if !obj.is_a?(Symbol)
        if obj.respond_to?(:to_sym)
          obj = obj.to_sym
        else
          raise MalformedPDFError, "expected object to be a Name"
        end
      end

      obj
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return an Integer or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting an Array and no other type will do.
    #
    # Some effort to cast to an int is made when the reference points to a non-integer.
    def deref_integer(key)
      obj = deref(key)

      return obj if obj.nil?

      if !obj.is_a?(Integer)
        if obj.respond_to?(:to_i)
          obj = obj.to_i
        else
          raise MalformedPDFError, "expected object to be an Integer"
        end
      end

      obj
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a Numeric or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting an Array and no other type will do.
    #
    # Some effort to cast to a number is made when the reference points to a non-number.
    def deref_number(key)
      obj = deref(key)

      return obj if obj.nil?

      if !obj.is_a?(Numeric)
        if obj.respond_to?(:to_f)
          obj = obj.to_f
        elsif obj.respond_to?(:to_i)
          obj.to_i
        else
          raise MalformedPDFError, "expected object to be a number"
        end
      end

      obj
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a PDF::Reader::Stream or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting a stream and no other type will do.
    def deref_stream(key)
      obj = deref(key)

      return obj if obj.nil?

      obj.tap { |obj|
        if !obj.is_a?(PDF::Reader::Stream)
          raise MalformedPDFError, "expected object to be a Stream or nil"
        end
      }
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a String or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting a string and no other type will do.
    #
    # Some effort to cast to a string is made when the reference points to a non-string.
    def deref_string(key)
      obj = deref(key)

      return obj if obj.nil?

      if !obj.is_a?(String)
        if obj.respond_to?(:to_s)
          obj = obj.to_s
        else
          raise MalformedPDFError, "expected object to be a string"
        end
      end

      obj
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a PDF Name (symbol), Array or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting a Name or Array and no other type will do.
    def deref_name_or_array(key)
      obj = deref(key)

      return obj if obj.nil?

      obj.tap { |obj|
        if !obj.is_a?(Symbol) && !obj.is_a?(Array)
          raise MalformedPDFError, "expected object to be an Array or Name"
        end
      }
    end

    # If key is a PDF::Reader::Reference object, lookup the corresponding
    # object in the PDF and return it. Otherwise return key untouched.
    #
    # Guaranteed to only return a PDF::Reader::Stream, Array or nil. If the dereference results in
    # any other type then a MalformedPDFError exception will raise. Useful when
    # expecting a stream or Array and no other type will do.
    def deref_stream_or_array(key)
      obj = deref(key)

      return obj if obj.nil?

      obj.tap { |obj|
        if !obj.is_a?(PDF::Reader::Stream) && !obj.is_a?(Array)
          raise MalformedPDFError, "expected object to be an Array or Stream"
        end
      }
    end

    # Recursively dereferences the object refered to be +key+. If +key+ is not
    # a PDF::Reader::Reference, the key is returned unchanged.
    #
    def deref!(key)
      deref_internal!(key, {})
    end

    def deref_array!(key)
      deref!(key).tap { |obj|
        if !obj.nil? && !obj.is_a?(Array)
          raise MalformedPDFError, "expected object (#{obj.inspect}) to be an Array or nil"
        end
      }
    end

    def deref_hash!(key)
      deref!(key).tap { |obj|
        if !obj.nil? && !obj.is_a?(Hash)
          raise MalformedPDFError, "expected object (#{obj.inspect}) to be a Hash or nil"
        end
      }
    end

    # Access an object from the PDF. key can be an int or a PDF::Reader::Reference
    # object.
    #
    # If an int is used, the object with that ID and a generation number of 0 will
    # be returned.
    #
    # If a PDF::Reader::Reference object is used the exact ID and generation number
    # can be specified.
    #
    # local_default is the object that will be returned if the requested key doesn't
    # exist.
    #
    def fetch(key, local_default = nil)
      obj = self[key]
      if obj
        return obj
      elsif local_default
        return local_default
      else
        raise IndexError, "#{key} is invalid" if key.to_i <= 0
      end
    end

    # iterate over each key, value. Just like a ruby hash.
    #
    def each(&block)
      @xref.each do |ref|
        yield ref, self[ref]
      end
    end
    alias :each_pair :each

    # iterate over each key. Just like a ruby hash.
    #
    def each_key(&block)
      each do |id, obj|
        yield id
      end
    end

    # iterate over each value. Just like a ruby hash.
    #
    def each_value(&block)
      each do |id, obj|
        yield obj
      end
    end

    # return the number of objects in the file. An object with multiple generations
    # is counted once.
    def size
      xref.size
    end
    alias :length :size

    # return true if there are no objects in this file
    #
    def empty?
      size == 0 ? true : false
    end

    # return true if the specified key exists in the file. key
    # can be an int or a PDF::Reader::Reference
    #
    def has_key?(check_key)
      # TODO update from O(n) to O(1)
      each_key do |key|
        if check_key.kind_of?(PDF::Reader::Reference)
          return true if check_key == key
        else
          return true if check_key.to_i == key.id
        end
      end
      return false
    end
    alias :include? :has_key?
    alias :key? :has_key?
    alias :member? :has_key?

    # return true if the specifiedvalue exists in the file
    #
    def has_value?(value)
      # TODO update from O(n) to O(1)
      each_value do |obj|
        return true if obj == value
      end
      return false
    end
    alias :value? :has_key?

    def to_s
      "<PDF::Reader::ObjectHash size: #{self.size}>"
    end

    # return an array of all keys in the file
    #
    def keys
      ret = []
      each_key { |k| ret << k }
      ret
    end

    # return an array of all values in the file
    #
    def values
      ret = []
      each_value { |v| ret << v }
      ret
    end

    # return an array of all values from the specified keys
    #
    def values_at(*ids)
      ids.map { |id| self[id] }
    end

    # return an array of arrays. Each sub array contains a key/value pair.
    #
    def to_a
      ret = []
      each do |id, obj|
        ret << [id, obj]
      end
      ret
    end

    # returns an array of PDF::Reader::References. Each reference in the
    # array points a Page object, one for each page in the PDF. The first
    # reference is page 1, second reference is page 2, etc.
    #
    # Useful for apps that want to extract data from specific pages.
    #
    def page_references
      root  = fetch(trailer[:Root])
      @page_references ||= begin
                             pages_root = deref_hash(root[:Pages]) || {}
                             get_page_objects(pages_root)
                           end
    end

    def encrypted?
      trailer.has_key?(:Encrypt)
    end

    def sec_handler?
      !!sec_handler
    end

    private

    # parse a traditional object from the PDF, starting from the byte offset indicated
    # in the xref table
    #
    def fetch_object(key)
      if xref[key].is_a?(Integer)
        buf = new_buffer(xref[key])
        decrypt(key, Parser.new(buf, self).object(key.id, key.gen))
      end
    end

    # parse a object that's embedded in an object stream in the PDF
    #
    def fetch_object_stream(key)
      if xref[key].is_a?(PDF::Reader::Reference)
        container_key = xref[key]
        stream = deref_stream(container_key)
        raise MalformedPDFError, "Object Stream cannot be nil" if stream.nil?
        object_streams[container_key] ||= PDF::Reader::ObjectStream.new(stream)
        object_streams[container_key][key.id]
      end
    end

    # Private implementation of deref!, which exists to ensure the `seen` argument
    # isn't publicly available. It's used to avoid endless loops in the recursion, and
    # doesn't need to be part of the public API.
    #
    def deref_internal!(key, seen)
      seen_key = key.is_a?(PDF::Reader::Reference) ? key : key.object_id

      return seen[seen_key] if seen.key?(seen_key)

      case object = deref(key)
      when Hash
        seen[seen_key] ||= {}
        object.each do |k, value|
          seen[seen_key][k] = deref_internal!(value, seen)
        end
        seen[seen_key]
      when PDF::Reader::Stream
        seen[seen_key] ||= PDF::Reader::Stream.new({}, object.data)
        object.hash.each do |k,value|
          seen[seen_key].hash[k] = deref_internal!(value, seen)
        end
        seen[seen_key]
      when Array
        seen[seen_key] ||= []
        object.each do |value|
          seen[seen_key] << deref_internal!(value, seen)
        end
        seen[seen_key]
      else
        object
      end
    end

    def decrypt(ref, obj)
      case obj
      when PDF::Reader::Stream then
        # PDF 32000-1:2008 7.5.8.2: "The cross-reference stream shall not be encrypted [...]."
        # Therefore we shouldn't try to decrypt it.
        obj.data = sec_handler.decrypt(obj.data, ref) unless obj.hash[:Type] == :XRef
        obj
      when Hash                then
        arr = obj.map { |key,val| [key, decrypt(ref, val)] }
        arr.each_with_object({}) { |(k,v), accum|
          accum[k] = v
        }
      when Array               then
        obj.collect { |item| decrypt(ref, item) }
      when String
        sec_handler.decrypt(obj, ref)
      else
        obj
      end
    end

    def new_buffer(offset = 0)
      PDF::Reader::Buffer.new(@io, :seek => offset)
    end

    def xref
      @xref
    end

    def object_streams
      @object_streams ||= {}
    end

    # returns an array of object references for all pages in this object store. The ordering of
    # the Array is significant and matches the page ordering of the document
    #
    def get_page_objects(obj)
      derefed_obj = deref_hash(obj)

      if derefed_obj.nil?
        raise MalformedPDFError, "Expected Page or Pages object, got nil"
      elsif derefed_obj[:Type] == :Page
        [obj]
      elsif derefed_obj[:Kids]
        kids = deref_array(derefed_obj[:Kids]) || []
        kids.map { |kid|
          get_page_objects(kid)
        }.flatten
      else
        raise MalformedPDFError, "Expected Page or Pages object"
      end
    end

    def read_version
      @io.seek(0)
      _m, version = *@io.read(10).to_s.match(/PDF-(\d.\d)/)
      @io.seek(0)
      version.to_f
    end

    def extract_io_from(input)
      if input.is_a?(IO) || input.is_a?(StringIO) || input.is_a?(Tempfile)
        input
      elsif File.file?(input.to_s)
        StringIO.new read_as_binary(input.to_s)
      else
        raise ArgumentError, "input must be an IO-like object or a filename (#{input.class})"
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
