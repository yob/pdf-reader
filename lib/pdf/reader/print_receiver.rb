class PDF::Reader
  class PrintReceiver

    attr_accessor :callbacks

    def initialize
      @callbacks = []
    end

    def respond_to?(meth)
      true
    end

    def method_missing(methodname, *args)
      puts "#{methodname} => #{args.inspect}"
    end
  end
end
