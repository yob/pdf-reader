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
  class Hash
    include Enumerable

    attr_accessor :default
    attr_reader :trailer

    def initialize(input)
      if input.kind_of?(IO)
        io = input
      elsif File.file?(input.to_s)
        if File.respond_to?(:binread)
          input = File.binread(input.to_s)
        else
          input = File.read(input.to_s)
        end
        io = StringIO.new(input)
      end
      buffer = PDF::Reader::Buffer.new(io)
      @xref  = PDF::Reader::XRef.new(buffer)
      @trailer = @xref.load
    end

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

    def each(&block)
      @xref.each do |ref, obj|
        yield ref, obj
      end
    end
    alias :each_pair :each

    def each_key(&block)
      each do |id, obj|
        yield id
      end
    end

    def each_value(&block)
      each do |id, obj|
        yield obj
      end
    end

    def size
      @xref.size
    end
    alias :length :size

    def empty?
      size == 0 ? true : false
    end

    # TODO update from O(n) to O(1)
    def has_key?(check_key)
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

    # TODO update from O(n) to O(1)
    def has_value?(value)
      each_value do |obj|
        return true if obj == value
      end
      return false
    end
    alias :value? :has_key?

    def to_s
      "<PDF::Hash size: #{self.size}>"
    end

    def keys
      ret = []
      each_key { |k| ret << k }
      ret
    end

    def values
      ret = []
      each_value { |v| ret << v }
      ret
    end

    def values_at(*ids)
      ids.map { |id| self[id] }
    end

    def to_a
      ret = []
      each do |id, obj|
        ret << [id, obj]
      end
      ret
    end

  end
end
