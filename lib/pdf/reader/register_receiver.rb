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
      callbacks << methodname.to_sym
    end
  end
end
