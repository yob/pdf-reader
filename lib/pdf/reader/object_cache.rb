# coding: utf-8

class PDF::Reader

  # A Hash-like object for caching commonly used objects from a PDF file.
  #
  # This is an internal class used by PDF::Reader::ObjectHash
  #
  class ObjectCache # nodoc

    # These object types use little memory and are accessed a heap of times as
    # part of random page access, so we'll cache the unmarshalled objects and
    # avoid lots of repetitive (and expensive) tokenising
    CACHEABLE_TYPES = [:Catalog, :Page, :Pages]

    def initialize
      @objects = {}
    end

    def [](key)
      @objects[key]
    end

    def []=(key, value)
      @objects[key] = value if cacheable?(value)
    end

    def fetch(key, local_default = nil)
      @objects.fetch(key, local_default)
    end

    def each(&block)
      @objects.each(&block)
    end
    alias :each_pair :each

    def each_key(&block)
      @objects.each_key(&block)
    end

    def each_value(&block)
      @objects.each_value(&block)
    end

    def size
      @objects.size
    end
    alias :length :size

    def empty?
      @objects.empty?
    end

    def has_key?(key)
      @objects.has_key?(key)
    end
    alias :include? :has_key?
    alias :key? :has_key?
    alias :member? :has_key?

    def has_value?(value)
      @objects.has_value?(value)
    end

    def to_s
      "<PDF::Reader::ObjectCache size: #{self.size}>"
    end

    def keys
      @objects.keys
    end

    def values
      @objects.values
    end

    private

    def cacheable?(obj)
      obj.is_a?(Hash) && CACHEABLE_TYPES.include?(obj[:Type])
    end


  end
end
