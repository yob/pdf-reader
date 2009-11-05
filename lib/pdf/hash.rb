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

    # TODO: need a way to specify "get most recent generation"
    #
    def [](pdf_id)
      return default if pdf_id.to_i <= 0

      begin
        @xref.object(PDF::Reader::Reference.new(pdf_id.to_i, 0))
      rescue
        return default
      end
    end

    def fetch(pdf_id, local_default = nil)
      raise ArgumentError if pdf_id.to_i <= 0

      @xref.object(PDF::Reader::Reference.new(pdf_id.to_i, 0))
    rescue
      if local_default
        return local_default
      else
        raise IndexError, "#{pdf_id} is invalid" if pdf_id.to_i <= 0
      end
    end

    def each(&block)
      @xref.each do |ref, obj|
        yield ref.id, obj
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
    def has_key?(pdf_id)
      each_key do |key|
        return true if pdf_id == key
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
