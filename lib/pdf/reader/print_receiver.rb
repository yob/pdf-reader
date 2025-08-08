# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  # A simple receiver that prints all operaters and parameters in the content
  # stream of a single page.
  #
  class PrintReceiver

    #: () -> Array[untyped]
    #: (Array[untyped]) -> void
    attr_accessor :callbacks

    #: () -> void
    def initialize
      @callbacks = []
    end

    #: (untyped) -> bool
    def respond_to?(meth)
      true
    end

    #: (Symbol, *untyped) -> void
    def method_missing(methodname, *args)
      puts "#{methodname} => #{args.inspect}"
    end
  end
end
