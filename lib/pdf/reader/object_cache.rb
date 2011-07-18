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
    CORE_TYPES = [:Catalog, :Page, :Pages]

    def initialize
      @core = {}
      @lfu  = {}
      @max_entries = 1000
      @buffer = 50
    end

    def [](key)
      if @core.has_key?(key)
        @core[key]
      elsif @lfu.has_key?(key)
        count = @lfu[key].first + 1
        obj   = @lfu[key].last
        @lfu[key] = [count, obj]
        obj
      else
        nil
      end
    end

    def []=(key, value)
      if core?(value)
        @core[key] = value
      else
        @lfu[key] = [1, value]
        prune
      end
    end

    def each(&block)
      @core.each(&block)
    end
    alias :each_pair :each

    def each_key(&block)
      @core.each_key(&block)
    end

    def each_value(&block)
      @core.each_value(&block)
    end

    def size
      @core.size + @lfu.size
    end
    alias :length :size

    def empty?
      @core.empty? && @lfu.empty?
    end

    def has_key?(key)
      @core.has_key?(key) || @lfu.has_key?(key)
    end
    alias :include? :has_key?
    alias :key? :has_key?
    alias :member? :has_key?

    def has_value?(value)
      @core.has_value?(value) || @lfu.has_value?(value)
    end

    def to_s
      "<PDF::Reader::ObjectCache core: #{@core.size} lfu: #{@lfu.size}>"
    end

    def keys
      @core.keys + @lfu.keys
    end

    def values
      @core.values + @lfu.values
    end

    private

    def core?(obj)
      obj.is_a?(Hash) && CORE_TYPES.include?(obj[:Type])
    end

    def prune
      return if @lfu.size < @max_entries

      lowest_count = @lfu.values.map(&:first).sort.first

      @lfu.select { |key, obj|
        obj.first == lowest_count
      }.keys.slice(0,@buffer).each do |key|
        @lfu.delete(key)
      end
    end

  end
end
