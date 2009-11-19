module PDF
  # Provides low level access to the objects in a PDF file via a hash-like
  # object.
  #
  # A PDF file can be viewed as a large hash map. It is a series of objects
  # stored at an exact byte offsets, and a table that maps object IDs to byte
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
  #     h = PDF::Hash.new("somefile.pdf")
  #     h[1]
  #     => 3469
  #
  #     h[PDF::Reader::Reference.new(1,0)]
  #     => 3469
  #
  class Hash
    include Enumerable

    attr_accessor :default
    attr_reader :trailer

    # Creates a new PDF:Hash object. input can be a string with a valid filename,
    # a string containing a PDF file, or an IO object.
    #
    def initialize(input)
      if input.kind_of?(IO) || input.kind_of?(StringIO)
        io = input
      elsif File.file?(input.to_s)
        if File.respond_to?(:binread)
          input = File.binread(input.to_s)
        else
          input = File.read(input.to_s)
        end
        io = StringIO.new(input)
      else
        raise ArgumentError, "input must be an IO-like object or a filename"
      end
      buffer = PDF::Reader::Buffer.new(io)
      @xref  = PDF::Reader::XRef.new(buffer)
      @trailer = @xref.load
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

      begin
        unless key.kind_of?(PDF::Reader::Reference)
          key = PDF::Reader::Reference.new(key.to_i, 0)
        end
        @xref.object(key)
      rescue
        return default
      end
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
    # local_deault is the object that will be returned if the requested key doesn't
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
      @xref.each do |ref, obj|
        yield ref, obj
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
      @xref.size
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
      "<PDF::Hash size: #{self.size}>"
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

  end
end
