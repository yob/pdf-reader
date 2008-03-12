class PDF::Reader
  class RegisterReceiver

    attr_accessor :callbacks

    def initialize
      @callbacks = []
    end

    def respond_to?(meth)
      true
    end

    def method_missing(methodname, *args)
      callbacks << {:name => methodname.to_sym, :args => args}
    end

    # count the number of times a callback fired
    def count(methodname)
      counter = 0
      callbacks.each { |cb| counter += 1 if cb[:name] == methodname}
      return counter
    end

    # return the details for every time the specified callback was fired
    def all(methodname)
      ret = []
      callbacks.each do |cb|
        ret << cb if cb[:name] == methodname
      end
      return ret
    end

    # return the details for the first time the specified callback was fired
    def first_occurance_of(methodname)
      callbacks.each do |cb|
        return cb if cb[:name] == methodname
      end
      return nil
    end

    # return the details for the final time the specified callback was fired
    def final_occurance_of(methodname)
      returnme = nil
      callbacks.each do |cb|
        returnme = cb if cb[:name] == methodname
      end
      return returnme
    end

    # return the first occurance of a particular series of callbacks
    def series(*methods)
      return nil if methods.empty?

      indexes = (0..(callbacks.size-1-methods.size))
      method_indexes = (0..(methods.size-1))
      match = nil

      indexes.each do |idx|
        count = methods.size
        method_indexes.each do |midx|
          count -= 1 if callbacks[idx+midx][:name] == methods[midx]
        end
        match = idx and break if count == 0
      end

      if match 
        return callbacks[match, methods.size]
      else
        return nil
      end
    end
  end
end
