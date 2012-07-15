# coding: utf-8

require 'forwardable'

class PDF::Reader
  # a size limited hash-like object. When full, the Least Recently Used
  # key is evicted.
  #
  class LruHash
    extend Forwardable

    def_delegators :@store, :each, :each_key, :each_value, :keys
    def_delegators :@store, :size, :empty?, :include?, :has_value?, :values

    def initialize(size = 10)
      @size  = size.to_i
      @store = {}
      @lru   = []
    end

    def [](key)
      set_lru(key)
      @store[key]
    end

    def fetch(key, local_default = nil)
      obj = self[key]
      if obj
        return obj
      elsif local_default
        return local_default
      else
        raise IndexError, "#{key} is invalid"
      end
    end

    def []=(key, value)
      @store[key] = value
      set_lru(key)
      @store.delete(@lru.pop) if @lru.size > @size
      value
    end

    private

    def set_lru(key)
      @lru.unshift(@lru.delete(key) || key)
    end
  end
end
