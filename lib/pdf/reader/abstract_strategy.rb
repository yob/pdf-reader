# coding: utf-8

class PDF::Reader

  class AbstractStrategy # :nodoc:

    def initialize(ohash, receiver, options = {})
      @ohash, @receiver, @options = ohash, receiver, options
    end

    private

    def options
      @options || {}
    end

    # calls the name callback method on the receiver class with params as the arguments
    #
    def callback (name, params=[])
      receiver.send(name, *params) if receiver.respond_to?(name)
    end

    # strings outside of page content should be in either PDFDocEncoding or UTF-16.
    def decode_strings(obj)
      case obj
      when String then
        if obj[0,2].unpack("C*").slice(0,2) == [254,255]
          PDF::Reader::Encoding.new(:UTF16Encoding).to_utf8(obj[2, obj.size])
        else
          PDF::Reader::Encoding.new(:PDFDocEncoding).to_utf8(obj)
        end
      when Hash   then obj.each { |key,val| obj[key] = decode_strings(val) }
      when Array  then obj.collect { |item| decode_strings(item) }
      else
        obj
      end
    end

    def info
      ohash.object(trailer[:Info])
    end

    def info?
      info ? true : false
    end

    def ohash
      @ohash
    end

    def pages
      ohash.object(root[:Pages])
    end

    def pages?
      pages ? true : false
    end

    def receiver
      @receiver
    end

    def root
      ohash.object(trailer[:Root])
    end

    def root?
      root ? true : false
    end

    def trailer
      ohash.trailer
    end

  end
end

